
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import List

router = APIRouter()

class Hub:
    def __init__(self):
        self.conns: List[WebSocket] = []
    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.conns.append(ws)
    def remove(self, ws: WebSocket):
        if ws in self.conns:
            self.conns.remove(ws)
    async def broadcast(self, data: dict):
        dead = []
        for ws in self.conns:
            try: await ws.send_json(data)
            except Exception: dead.append(ws)
        for d in dead: self.remove(d)

hub = Hub()

@router.websocket("/ws/anchors")
async def ws_anchors(ws: WebSocket):
    await hub.connect(ws)
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        hub.remove(ws)
