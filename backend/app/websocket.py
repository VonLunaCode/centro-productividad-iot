import json
from fastapi import WebSocket
from typing import List, Dict

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self._device_status: Dict[str, str] = {}

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        # Enviar el estado actual de cada dispositivo a la nueva conexión
        for device_id, status in self._device_status.items():
            try:
                await websocket.send_text(json.dumps({
                    "type": "device_status",
                    "device_id": device_id,
                    "status": status,
                }))
            except Exception:
                pass

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        dead = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                dead.append(connection)
        for c in dead:
            self.disconnect(c)

    async def broadcast_device_status(self, device_id: str, status: str):
        self._device_status[device_id] = status
        await self.broadcast(json.dumps({
            "type": "device_status",
            "device_id": device_id,
            "status": status,
        }))

manager = ConnectionManager()
