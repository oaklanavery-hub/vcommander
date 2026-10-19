#!/usr/bin/env python3
"""Check the real container's public WebSocket protocol without extra packages."""
import argparse
import base64
import json
import os
import socket
import struct
import time


def receive_exact(stream, length):
    result = b""
    while len(result) < length:
        block = stream.recv(length - len(result))
        if not block:
            raise RuntimeError("WebSocket closed early")
        result += block
    return result


def check(port):
    key = base64.b64encode(os.urandom(16)).decode()
    with socket.create_connection(("127.0.0.1", port), timeout=5) as stream:
        stream.sendall((f"GET / HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nUpgrade: websocket\r\n"
                        f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        response = b""
        while not response.endswith(b"\r\n\r\n"):
            response += receive_exact(stream, 1)
            if len(response) > 8192:
                raise RuntimeError("Oversized handshake")
        if not response.startswith(b"HTTP/1.1 101"):
            raise RuntimeError("WebSocket upgrade failed")
        data = json.dumps({"v": 2, "type": "clock", "at": 1234}).encode()
        mask = os.urandom(4)
        stream.sendall(bytes([0x81, 0x80 | len(data)]) + mask + bytes(v ^ mask[i % 4] for i, v in enumerate(data)))
        header = receive_exact(stream, 2)
        if header[0] & 0x0F != 1 or header[1] & 0x80:
            raise RuntimeError("Expected unmasked server text frame")
        length = header[1] & 0x7F
        if length == 126:
            length = struct.unpack("!H", receive_exact(stream, 2))[0]
        elif length == 127:
            length = struct.unpack("!Q", receive_exact(stream, 8))[0]
        if length > 8192:
            raise RuntimeError("Oversized clock reply")
        reply = json.loads(receive_exact(stream, length))
        if reply.get("v") != 2 or reply.get("type") != "clock" or reply.get("at") != 1234 or not isinstance(reply.get("server_time"), (int, float)):
            raise RuntimeError("Invalid authority response")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=10000)
    args = parser.parse_args()
    deadline = time.monotonic() + 45
    while True:
        try:
            check(args.port)
            print("Private container passed: real WebSocket upgrade and protocol-v2 clock response.")
            break
        except (OSError, RuntimeError, ValueError):
            if time.monotonic() >= deadline:
                raise
            time.sleep(0.25)
