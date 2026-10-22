"""Loopback desktop bridge to one fixed container endpoint; not a general proxy."""
import selectors
import socket
import socketserver

class DesktopBridge(socketserver.BaseRequestHandler):
    def handle(self):
        upstream = socket.create_connection(('oregon-reference-study', 6080), timeout=10)
        with upstream, selectors.DefaultSelector() as selector:
            self.request.settimeout(None)
            upstream.settimeout(None)
            selector.register(self.request, selectors.EVENT_READ, upstream)
            selector.register(upstream, selectors.EVENT_READ, self.request)
            while True:
                for key, _ in selector.select(timeout=120):
                    data = key.fileobj.recv(65536)
                    if not data:
                        return
                    key.data.sendall(data)

class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

with Server(('0.0.0.0', 6080), DesktopBridge) as server:
    server.serve_forever()
