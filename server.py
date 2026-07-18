import asyncio
import websockets
import json
import time
import ctypes
from ctypes import wintypes

user32 = ctypes.windll.user32

last_click_time = 0

def click_mouse():
    user32.mouse_event(0x0002, 0, 0, 0, 0)
    time.sleep(0.02)
    user32.mouse_event(0x0004, 0, 0, 0, 0)

async def handle_client(websocket):
    global last_click_time
    print("Client connected")
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                
                if data.get("action") == "press_f":
                    current_time = time.time()
                    
                    if current_time - last_click_time > 0.05:
                        click_mouse()
                        print("Mouse left click")
                        last_click_time = current_time
                        
            except:
                pass
                
    except:
        print("Client disconnected")

async def start_server():
    async with websockets.serve(handle_client, "localhost", 8766):
        print("Server started on ws://localhost:8766")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(start_server())
