from fastapi import WebSocket
from typing import Dict, List
import json
import random
import string

class ConnectionManager:
    def __init__(self):
        # Maps room_code to a list of connected WebSockets
        self.active_connections: Dict[str, List[WebSocket]] = {}
        # Maps room_code to game state
        self.games: Dict[str, dict] = {}

    async def connect(self, websocket: WebSocket, room_code: str):
        await websocket.accept()
        if room_code not in self.active_connections:
            self.active_connections[room_code] = []
        self.active_connections[room_code].append(websocket)
        
        # Initialize game state if it doesn't exist
        if room_code not in self.games:
             self.games[room_code] = {
                 "host": None,
                 "players": [],
                 "challenge": None,
                 "state": "waiting", # waiting, playing, finished
                 "scores": {}
             }

    def disconnect(self, websocket: WebSocket, room_code: str):
        if room_code in self.active_connections:
            if websocket in self.active_connections[room_code]:
                self.active_connections[room_code].remove(websocket)
            if not self.active_connections[room_code]:
                # Clean up empty rooms
                del self.active_connections[room_code]
                if room_code in self.games:
                    del self.games[room_code]

    async def broadcast(self, message: dict, room_code: str):
        if room_code in self.active_connections:
            for connection in self.active_connections[room_code]:
                try:
                    await connection.send_text(json.dumps(message))
                except Exception as e:
                    print(f"Error sending message: {e}")

    def generate_room_code(self):
        return ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))

manager = ConnectionManager()
