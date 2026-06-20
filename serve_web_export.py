import mimetypes
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("application/octet-stream", ".pck")
mimetypes.add_type("text/javascript", ".js")


class GodotWebHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()


def run():
    server = ThreadingHTTPServer(("localhost", 8000), GodotWebHandler)
    print("Serving Godot Web export at http://localhost:8000/")
    server.serve_forever()


if __name__ == "__main__":
    run()
