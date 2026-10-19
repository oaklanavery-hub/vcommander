#!/usr/bin/env python3
"""Isolated real-protocol load test; never connects to the public game server."""
import argparse
import asyncio
import base64
import contextlib
import gzip
import hashlib
import json
import math
import os
from pathlib import Path
import socket
import struct
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
WIRE_LIMIT = 8 * 1024 * 1024


class Peer:
    def __init__(self, port):
        self.port = port
        self.state = {}
        self.room = self.token = ""
        self.replays = {}
        self.errors = []
        self.rtts = []
        self.pending_clocks = {}
        self.reader_task = self.clock_task = None
        self.expected_close = False

    async def connect(self):
        self.expected_close = False
        self.state = {}
        self.pending_clocks.clear()
        self.reader, self.writer = await asyncio.wait_for(asyncio.open_connection("127.0.0.1", self.port), 10)
        key = base64.b64encode(os.urandom(16)).decode()
        self.writer.write((f"GET / HTTP/1.1\r\nHost: 127.0.0.1:{self.port}\r\nUpgrade: websocket\r\n"
                           f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        await self.writer.drain()
        header = await asyncio.wait_for(self.reader.readuntil(b"\r\n\r\n"), 10)
        accept = base64.b64encode(hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest())
        assert header.startswith(b"HTTP/1.1 101") and accept.lower() in header.lower(), "Invalid WebSocket upgrade"
        self.reader_task = asyncio.create_task(self.read_loop())
        self.clock_task = asyncio.create_task(self.clock_loop())

    async def frame(self, opcode, data):
        mask = os.urandom(4)
        size = len(data)
        if size < 126:
            header = bytes([0x80 | opcode, 0x80 | size])
        elif size < 65536:
            header = bytes([0x80 | opcode, 0xFE]) + struct.pack("!H", size)
        else:
            header = bytes([0x80 | opcode, 0xFF]) + struct.pack("!Q", size)
        self.writer.write(header + mask + bytes(v ^ mask[i % 4] for i, v in enumerate(data)))
        await self.writer.drain()

    async def send(self, kind, **values):
        await self.frame(1, json.dumps({"v": 2, "type": kind, **values}, separators=(",", ":")).encode())

    async def act(self, kind, **values):
        await self.send(kind, round=self.state["round"], revision=self.state["revision"], **values)

    async def clock_loop(self):
        while True:
            at = time.monotonic_ns() // 1000000
            self.pending_clocks[at] = time.monotonic()
            await self.send("clock", at=at)
            await asyncio.sleep(0.5)

    async def read_loop(self):
        fragments = bytearray()
        message_kind = None
        try:
            while True:
                a, b = await self.reader.readexactly(2)
                assert not b & 0x80, "Masked server frame"
                length = b & 127
                if length == 126:
                    length = struct.unpack("!H", await self.reader.readexactly(2))[0]
                elif length == 127:
                    length = struct.unpack("!Q", await self.reader.readexactly(8))[0]
                assert length <= WIRE_LIMIT, "Oversized frame"
                payload = await self.reader.readexactly(length)
                kind = a & 15
                if kind == 9:
                    await self.frame(10, payload)
                    continue
                if kind == 10:
                    continue
                if kind == 8:
                    raise ConnectionError("Server closed WebSocket")
                if kind in (1, 2):
                    assert message_kind is None, "Interleaved messages"
                    message_kind = kind
                else:
                    assert kind == 0 and message_kind is not None, "Invalid continuation"
                fragments.extend(payload)
                assert len(fragments) <= WIRE_LIMIT, "Oversized message"
                if not a & 0x80:
                    continue
                received_at = time.monotonic()
                raw = bytes(fragments)
                if message_kind == 2:
                    # Decoding runs outside the server's CPU/memory cgroup.
                    message = await asyncio.to_thread(decode_replay, raw)
                    self.replays[int(message["round"])] = {"hash": hashlib.sha256(raw).hexdigest(),
                        "bytes": len(raw), "received_at": received_at, **message["summary"]}
                else:
                    message = json.loads(raw)
                    kind = message["type"]
                    if kind == "state":
                        self.state = message
                    elif kind == "session":
                        self.room, self.token = message["room"], message["token"]
                    elif kind == "clock":
                        sent = self.pending_clocks.pop(message["at"], None)
                        if sent is not None:
                            self.rtts.append((received_at - sent) * 1000)
                    elif kind == "error":
                        self.errors.append(message["code"])
                fragments.clear()
                message_kind = None
        except asyncio.CancelledError:
            raise
        except Exception as error:
            if not self.expected_close:
                self.errors.append(type(error).__name__ + ": " + str(error))

    async def close(self):
        self.expected_close = True
        for task in (self.clock_task, self.reader_task):
            if task:
                task.cancel()
                with contextlib.suppress(asyncio.CancelledError, OSError):
                    await task
        if hasattr(self, "writer"):
            self.writer.close()
            with contextlib.suppress(OSError):
                await self.writer.wait_closed()


def decode_replay(raw):
    expanded = gzip.decompress(raw)
    assert len(expanded) <= 64 * 1024 * 1024, "Oversized expanded replay"
    message = json.loads(expanded)
    assert message["v"] == 2 and message["type"] == "battle", "Invalid replay"
    result = message["replay"]
    assert result["winner"] in ("player", "opponent", "draw") and 0 <= result["duration"] <= 120.001
    return {"round": message["round"], "summary": {"winner": result["winner"], "duration": result["duration"],
        "events": len(result["events"]), "frames": len(result["frames"]), "expanded_bytes": len(expanded),
        "starting_units": len(result["frames"][0]["units"])}}


async def until(predicate, peers, label, timeout=90):
    end = time.monotonic() + timeout
    while not predicate():
        errors = [e for p in peers for e in p.errors]
        if errors:
            raise RuntimeError(f"{label}: {errors}")
        if time.monotonic() >= end:
            raise TimeoutError(f"{label}; phases={[p.state.get('phase') for p in peers]}")
        await asyncio.sleep(0.01)


async def exercise(port, manifest, rooms, profile, cycles, progress):
    peers = []
    pairs = []
    batches = []
    reconnect_ms = None
    try:
        setups = manifest["setups"]
        for i in range(rooms):
            eligible = [s for s in setups if s["element"] == profile] if profile in ("earth", "slime") else setups
            host_setup = eligible[i % len(eligible)]
            guest_setup = host_setup if profile != "normal" else eligible[(i + 1) % len(eligible)]
            pair = [Peer(port), Peer(port)]
            peers.extend(pair)
            await pair[0].connect()
            await pair[0].send("create", content=manifest["content"], commander=host_setup["commander"], cards=host_setup["cards"])
            await until(lambda: bool(pair[0].room), peers, "create room", 10)
            await pair[1].connect()
            await pair[1].send("join", content=manifest["content"], room=pair[0].room,
                               commander=guest_setup["commander"], cards=guest_setup["cards"])
            pairs.append(pair)
        await until(lambda: all(p.state.get("phase") == "draft" for p in peers), peers, "all rooms draft", 10)
        overflow = Peer(port)
        try:
            await overflow.connect()
            await overflow.send("create", content=manifest["content"], commander=setups[0]["commander"], cards=setups[0]["cards"])
            await until(lambda: bool(overflow.errors), [], "capacity rejection", 10)
            assert overflow.errors == ["server_full"], "Overflow must reject without disturbing existing rooms"
        finally:
            await overflow.close()
        for cycle in range(1, cycles + 1):
            active = [p for p in peers if p.state.get("phase") != "complete"]
            if not active:
                break
            await until(lambda: all(p.state.get("phase") == "draft" and p.state.get("round") == cycle for p in active), peers, "next draft", 15)
            if profile != "normal":
                await until(lambda: all(p.state.get("points") == 1 and all(p.state["self"]["unit_counts"].get(c["id"]) == c["unit_cap"]
                    for c in p.state["self"]["cards"]) for p in active), peers, "capped fixture", 15)
            start = time.monotonic()
            while any(p.state.get("phase") == "draft" and p.state.get("points", 0) > 0 for p in active):
                selecting = [p for p in active if p.state.get("phase") == "draft" and p.state.get("points", 0) > 0]
                revisions = {p: p.state["revision"] for p in selecting}
                await asyncio.gather(*(p.act("skill") if profile != "normal" else p.act("pick", index=0) for p in selecting))
                await until(lambda: all(p.state.get("revision", 0) > revisions[p] for p in selecting), peers, "draft acknowledgments", 30)
            preparation_start = time.monotonic()
            # Reconnect one reserved seat during the first synchronized workload.
            if cycle == 1:
                p = pairs[0][1]
                await asyncio.sleep(0.1)
                reconnect_start = time.monotonic()
                await p.close()
                await p.connect()
                await p.send("resume", content=manifest["content"], room=p.room, token=p.token)
                await until(lambda: p.state.get("connected", {}).get(p.state.get("you"), False), peers, "reserved-seat resume", 15)
                reconnect_ms = (time.monotonic() - reconnect_start) * 1000
            await until(lambda: all(p.state.get("phase") == "loading" for p in active), peers, "all simulations and encoding", 180)
            prepared = time.monotonic()
            await asyncio.gather(*(p.send("replay", round=cycle) for p in active))
            await until(lambda: all(cycle in p.replays for p in active), peers, "all replay downloads", 45)
            downloaded = time.monotonic()
            for pair in pairs:
                if pair[0] not in active:
                    continue
                a, b = (p.replays[cycle] for p in pair)
                assert a["hash"] == b["hash"], "Players received different replays"
                if profile == "endurance":
                    assert a["duration"] >= 119.99, "Endurance fixture must exercise the full 120-second round"
                batches.append({"round": cycle, "room": pairs.index(pair), **{k: v for k, v in a.items() if k not in ("hash", "received_at")}})
            await asyncio.gather(*(p.act("ready") for p in active))
            await until(lambda: all(p.state.get("phase") == "playing" for p in active), peers, "shared playback", 15)
            for pair in pairs:
                if pair[0] in active:
                    assert pair[0].state["play_at"] == pair[1].state["play_at"] and pair[0].state["play_until"] == pair[1].state["play_until"]
            await until(lambda: all(p.state.get("phase") in ("replay", "complete") for p in active), peers, "server scoring", 15)
            for pair in pairs:
                assert pair[0].state["losses"] == pair[1].state["losses"] and pair[0].state["winner"] == pair[1].state["winner"], "Results disagree"
            print(json.dumps({"rooms": rooms, "profile": profile, "round": cycle, "prepare_s": round(prepared - preparation_start, 3),
                "draft_to_download_s": round(downloaded - start, 3)}), flush=True)
            for row in batches:
                if row["round"] == cycle:
                    row.update(prepare_seconds=prepared - preparation_start, download_seconds=downloaded - prepared,
                               draft_to_download_seconds=downloaded - start)
            # Preserve completed rounds even if a later round drops connections
            # or the kernel kills the isolated container.
            progress.update(battles=len(batches), observations=list(batches),
                prepare_max_seconds=max(b["prepare_seconds"] for b in batches),
                download_max_seconds=max(b["download_seconds"] for b in batches))
            continuing = [p for p in active if p.state.get("phase") == "replay"]
            if cycle < cycles:
                await asyncio.gather(*(p.act("continue") for p in continuing))
        assert not [e for p in peers for e in p.errors], "Unexpected protocol errors"
        if profile == "normal":
            assert all(p.state.get("phase") == "complete" for p in peers), "Normal fixture did not finish whole matches"
        await asyncio.sleep(0.3)
        rtts = sorted(t for p in peers for t in p.rtts)
        assert rtts and batches, "No workload or latency observations"
        return {"functional_pass": True, "battles": len(batches), "observations": batches,
            "clock_samples": len(rtts), "clock_p95_ms": rtts[math.ceil(len(rtts) * 0.95) - 1],
            "clock_max_ms": max(rtts), "reconnect_ms": reconnect_ms,
            "prepare_max_seconds": max(b["prepare_seconds"] for b in batches),
            "download_max_seconds": max(b["download_seconds"] for b in batches)}
    finally:
        await asyncio.gather(*(p.close() for p in peers), return_exceptions=True)


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, ValueError):
        return {}


def command(args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, text=True, timeout=45, **kwargs).stdout.strip()


def run_case(args, rooms, profile):
    result = {"rooms": rooms, "players": rooms * 2, "profile": profile, "mode": "docker" if args.image else "native-smoke"}
    with tempfile.TemporaryDirectory(prefix="vcommander-capacity-") as temp:
        directory = Path(temp)
        directory.chmod(0o777)
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        container = None
        process = None
        log_file = None
        initialized = False
        try:
            fixture_args = ["--profile=" + profile, "--rooms=" + str(rooms)]
            if args.image:
                container = command(["docker", "run", "--detach", "--memory", "512m", "--memory-swap", "512m", "--cpus", "0.15",
                    "--publish", f"127.0.0.1:{port}:10000", "--env", f"PVP_MAX_ROOMS={rooms}",
                    "--mount", f"type=bind,src={directory},dst=/bench",
                    "--mount", f"type=bind,src={ROOT / 'tools/private_capacity_server.gd'},dst=/app/tools/private_capacity_server.gd,readonly",
                    args.image, "godot", "--headless", "--path", ".", "--script", "tools/private_capacity_server.gd", "--",
                    "--output-dir=/bench", "--port=10000", "--listen=0.0.0.0", *fixture_args])
            else:
                log_file = (directory / "process.log").open("w")
                process = subprocess.Popen([args.godot, "--headless", "--path", str(ROOT), "--script", "tools/private_capacity_server.gd", "--",
                    "--output-dir=" + str(directory), "--port=" + str(port), *fixture_args], stdout=log_file, stderr=subprocess.STDOUT,
                    env={**os.environ, "PVP_MAX_ROOMS": str(rooms)})
            deadline = time.monotonic() + 60
            manifest = {}
            while time.monotonic() < deadline:
                manifest = read_json(directory / "manifest.json")
                if manifest:
                    break
                if process and process.poll() is not None:
                    raise RuntimeError("Fixture exited before listening")
                time.sleep(0.1)
            assert manifest and manifest["room_limit"] == rooms, "Server did not initialize requested room limit"
            initialized = True
            result.update(asyncio.run(asyncio.wait_for(exercise(port, manifest, rooms, profile, 16 if profile == "normal" else args.cycles, result), timeout=540)))
        except Exception as error:
            result.update(functional_pass=False, failure=type(error).__name__ + ": " + str(error))
        finally:
            result["server"] = read_json(directory / "server.json")
            if container:
                inspect = json.loads(command(["docker", "inspect", container]))[0]
                result["oom_killed"] = inspect["State"]["OOMKilled"]
                result["container_running_at_end"] = inspect["State"]["Running"]
                result["memory_limit_bytes"] = inspect["HostConfig"]["Memory"]
                result["cpu_limit"] = inspect["HostConfig"]["NanoCpus"] / 1e9
                log_result = subprocess.run(["docker", "logs", container], capture_output=True, text=True, timeout=15)
                logs = log_result.stdout + log_result.stderr
                command(["docker", "rm", "--force", container])
            elif process:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)
                log_file.close()
                logs = (directory / "process.log").read_text()
            else:
                logs = ""
            # Native cgroup readings describe the entire development container,
            # and must never be presented as per-server capacity measurements.
            if not args.image:
                result["server"] = {k: v for k, v in result["server"].items() if k not in ("memory.current", "memory.peak", "memory.max", "cpu.max", "cpu.stat")}
            result["server_errors"] = [l for l in logs.splitlines() if "ERROR:" in l or "SCRIPT ERROR:" in l]
            if result["server_errors"] or result.get("oom_killed"):
                result["functional_pass"] = False
            result["measurement_valid"] = initialized or result.get("oom_killed", False)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            (args.output.parent / f"capacity-{rooms}-{profile}.log").write_text(logs)
    peak = result.get("server", {}).get("memory.peak")
    result["peak_memory_mib"] = int(peak) / 1024**2 if args.image and str(peak).isdigit() else None
    result["memory_peak_is_lower_bound"] = result.get("oom_killed", False)
    result["within_test_budgets"] = bool(args.image and result.get("functional_pass") and result["peak_memory_mib"] is not None
        and result["peak_memory_mib"] <= 435.2 and result.get("prepare_max_seconds", 1e9) <= 10
        and result.get("clock_p95_ms", 1e9) <= 1000 and result.get("clock_max_ms", 1e9) <= 5000
        and result.get("server", {}).get("peak_jobs", 0) >= rooms)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--image", help="Already-built production Docker image")
    mode.add_argument("--godot", help="Unconstrained native harness smoke check only")
    parser.add_argument("--rooms", default="1,2,3,4")
    parser.add_argument("--profiles", default="normal,earth,slime,mixed,crowded,endurance")
    parser.add_argument("--cycles", type=int, default=2)
    parser.add_argument("--output", type=Path, default=ROOT / "build/capacity/report.json")
    args = parser.parse_args()
    rooms = [int(v) for v in args.rooms.split(",")]
    profiles = args.profiles.split(",")
    assert rooms and all(1 <= r <= 4 for r in rooms) and profiles and all(p in ("normal", "earth", "slime", "mixed", "crowded", "endurance") for p in profiles)
    assert 1 <= args.cycles <= 2, "Capped fixture preserves the two-use skill budget"
    report = {"source": os.environ.get("GITHUB_SHA", "local"), "limits": {"memory_mib": 512, "cpu": 0.15},
        "budgets": {"memory_headroom_percent": 15, "prepare_seconds": 10, "clock_p95_ms": 1000, "clock_max_ms": 5000},
        "method": "Real protocol/worker/encoding, synthetic capped rosters, accelerated presentation wait, isolated from live service", "cases": []}
    for room_count in rooms:
        for profile in profiles:
            result = run_case(args, room_count, profile)
            report["cases"].append(result)
            args.output.write_text(json.dumps(report, indent=2) + "\n")
            print("CAPACITY " + json.dumps({k: v for k, v in result.items() if k not in ("observations", "server")}), flush=True)
    # Capacity failures are measurements, not a reason to discard the report.
    # Each case carries its independent functional and performance verdicts.
    print("Capacity measurements saved:", args.output, flush=True)
    if not all(case["measurement_valid"] for case in report["cases"]):
        raise SystemExit("Invalid measurement: the isolated server did not initialize")


if __name__ == "__main__":
    main()
