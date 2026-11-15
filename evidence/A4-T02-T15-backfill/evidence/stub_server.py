#!/usr/bin/env python3
"""Loopback-only GitHub fixture server; unknown endpoints fail closed."""
import base64
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlsplit

root = Path(sys.argv[1])
prefix = '/repos/xy3293/muse-hub-test/'

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        fixture = json.loads((root / 'fixture.json').read_text())
        with (root / 'requests.jsonl').open('a') as stream:
            stream.write(json.dumps({'case': fixture['case'], 'path': self.path}) + '\n')
        url = urlsplit(self.path)
        code = 200
        page = int(parse_qs(url.query).get("page", ["1"])[0])
        next_page = False
        if url.path == prefix + 'compare/' + fixture['cursor'] + '...' + fixture['head']:
            pages = fixture.get('compare_pages', [fixture.get('compare_shas', list(fixture['commits']))])
            body = {'status': 'ahead', 'commits': [{'sha': sha} for sha in pages[page - 1]]}
            next_page = page < len(pages)
        elif url.path.startswith(prefix + 'commits/') and url.path.rsplit('/', 1)[-1] in fixture['commits']:
            body = fixture['commits'][url.path.rsplit('/', 1)[-1]]
        elif url.path == prefix + 'contents/BOARD.md' and parse_qs(url.query).get('ref') == [fixture['head']]:
            code = fixture.get('board_http', 200)
            body = {'encoding': 'base64', 'content': base64.encodebytes(fixture['board'].encode()).decode()}
        elif url.path == prefix + 'issues/comments':
            pages = fixture.get('comment_pages', [fixture.get('comments', [])])
            body = pages[page - 1]
            next_page = page < len(pages)
        else:
            code, body = 404, {'message': 'unexpected request'}
        if fixture.get('fault'):
            code = fixture['fault'].get('code', 200)
            time.sleep(fixture['fault'].get('delay', 0))
            body = {'message': 'injected fault'}
        payload = json.dumps(body).encode()
        self.send_response(code)
        if next_page:
            query = parse_qs(url.query)
            query['page'] = [str(page + 1)]
            link = f'http://127.0.0.1:{self.server.server_port}{url.path}?' + urlencode(query, doseq=True)
            self.send_header('Link', f'<{link}>; rel="next"')
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        try:
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError):
            pass

server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
(root / 'port').write_text(str(server.server_port))
server.serve_forever()
