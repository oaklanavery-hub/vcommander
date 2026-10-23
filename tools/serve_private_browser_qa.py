#!/usr/bin/env python3
"""Serve an exported game with an opt-in browser-only QA entry point."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
from urllib.parse import parse_qs, urlsplit


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        query = parse_qs(urlsplit(self.path).query)
        if urlsplit(self.path).path == "/index.html" and query.get("qa_role", [""])[0] in ("host", "guest", "local"):
            content = Path(self.directory, "index.html").read_text()
            match = re.search(r"const GODOT_CONFIG = (\{[^\n]+\});", content)
            if not match:
                self.send_error(500, "Export configuration not found")
                return
            config = json.loads(match.group(1))
            config["args"] = ["--",
                              "--role=" + query["qa_role"][0], "--room=" + query.get("room", [""])[0],
                              "--probe-stage=" + query.get("qa_stage", ["prepare"])[0]]
            content = content[:match.start(1)] + json.dumps(config) + content[match.end(1):]
            # Release Web templates disable --script/--scene overrides. Preload
            # Godot's standard project override into this QA browser's memory;
            # the exported pack and normal game's startup remain identical.
            override = '[application]\nrun/main_scene="res://tests/browser_private_driver.tscn"\n'
            content = content.replace("const engine = new Engine(GODOT_CONFIG);",
                                      "const engine = new Engine(GODOT_CONFIG);\n"
                                      "engine.preloadFile(new TextEncoder().encode(" + json.dumps(override) + "), 'override.cfg');")
            data = content.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            super().do_GET()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", default="build/web")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    ThreadingHTTPServer(("127.0.0.1", args.port), partial(Handler, directory=args.directory)).serve_forever()
