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
        if urlsplit(self.path).path == "/index.html" and query.get("qa_role", [""])[0] in ("host", "guest"):
            content = Path(self.directory, "index.html").read_text()
            match = re.search(r"const GODOT_CONFIG = (\{[^\n]+\});", content)
            if not match:
                self.send_error(500, "Export configuration not found")
                return
            config = json.loads(match.group(1))
            config["args"] = ["--script", "res://tests/browser_private_driver.gd", "--",
                              "--role=" + query["qa_role"][0], "--room=" + query.get("room", [""])[0]]
            content = content[:match.start(1)] + json.dumps(config) + content[match.end(1):]
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
