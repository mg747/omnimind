from fastapi import FastAPI, BackgroundTasks, HTTPException, Depends, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from asset_pipeline import AssetPipeline
from simulation_generator import SimulationGenerator
import os
from dotenv import load_dotenv
from models import init_db, get_db, ChallengeModel, UserModel
import json
from sqlalchemy.orm import Session
from ws_manager import manager

load_dotenv()
init_db()

app = FastAPI(title="OmniMind Backend")

# Enable CORS for Flutter Web (Development Environment)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from challenge_generator import ChallengeGenerator

# Initialize services
asset_pipeline = AssetPipeline()
simulation_generator = SimulationGenerator()
challenge_generator = ChallengeGenerator()

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/play")
async def serve_app():
    return FileResponse("static/index.html")

@app.get("/about")
async def serve_about():
    return FileResponse("static/about.html")

@app.get("/rules")
async def serve_rules():
    return FileResponse("static/rules.html")

@app.get("/privacy")
async def serve_privacy():
    return FileResponse("static/privacy.html")

@app.get("/terms")
async def serve_terms():
    return FileResponse("static/terms.html")

@app.get("/support")
async def serve_support():
    return FileResponse("static/support.html")

# Models
class ActionRequest(BaseModel):
    action: str
    inventory: List[str] = []

class ChallengeRequest(BaseModel):
    topic: str
    difficulty: str
    is_premium: bool = False

class VideoGenerationRequest(BaseModel):
    prompt: str
    image_url: str
    type: str = "video"
class UserRequest(BaseModel):
    username: str

class RewardRequest(BaseModel):
    amount: int

# Endpoints

@app.get("/")
async def root():
    response = FileResponse("static/index.html")
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

@app.get("/status")
async def check_status():
    """
    Checks which AI services are active based on env vars.
    """
    return {
        "logic_engine": "ONLINE" if os.getenv("OPENAI_API_KEY") else "OFFLINE (Fallback)",
        "asset_engine": "ONLINE" if os.getenv("RUNWAYML_API_SECRET") else "OFFLINE (Placeholder)",
        "memory_core": "ONLINE" if os.getenv("PINECONE_API_KEY") else "OFFLINE (Stateless)"
    }

@app.post("/challenges/generate")
async def generate_challenge_endpoint(req: ChallengeRequest, db: Session = Depends(get_db)):
    try:
        challenge = challenge_generator.generate_challenge(req.topic, req.difficulty, req.is_premium)
        
        # Save to SQLite Database
        new_challenge = ChallengeModel(
            id=challenge.get("id", ""),
            topic=req.topic,
            difficulty=req.difficulty,
            scenario=challenge.get("scenario", ""),
            options_json=json.dumps(challenge.get("options", [])),
            correct_option_id=challenge.get("correct_option_id", ""),
            explanation=challenge.get("explanation", ""),
            is_premium=req.is_premium
        )
        db.add(new_challenge)
        db.commit()
        
        return new_challenge.to_dict()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- USER PROFILES & ECONOMY ---

@app.post("/users/login")
async def user_login(req: UserRequest, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.username == req.username).first()
    if not user:
        # Create new user
        user = UserModel(username=req.username)
        db.add(user)
        db.commit()
    return user.to_dict()

@app.get("/users/{user_id}")
async def get_user_profile(user_id: str, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user.to_dict()

@app.put("/users/{user_id}")
async def update_username(user_id: str, req: UserRequest, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check for conflict
    existing = db.query(UserModel).filter(UserModel.username == req.username).first()
    if existing and existing.id != user_id:
        raise HTTPException(status_code=400, detail="Username already taken")
        
    user.username = req.username
    db.commit()
    return user.to_dict()

@app.delete("/users/{user_id}")
async def delete_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    return {"status": "success", "message": "Account Deleted"}

@app.post("/users/{user_id}/reward")
async def reward_user(user_id: str, req: RewardRequest, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
         raise HTTPException(status_code=404, detail="User not found")
    
    user.balance += req.amount
    user.games_played += 1
    db.commit()
    return user.to_dict()

@app.get("/challenges/{challenge_id}")
async def get_challenge(challenge_id: str, db: Session = Depends(get_db)):
    challenge = db.query(ChallengeModel).filter(ChallengeModel.id == challenge_id).first()
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")
    return challenge.to_dict()

# --- MULTIPLAYER WEBSOCKETS ---

@app.get("/multiplayer/host")
async def host_game():
    code = manager.generate_room_code()
    # Ensure it's unique
    while code in manager.active_connections:
        code = manager.generate_room_code()
    return {"room_code": code}

@app.websocket("/ws/{room_code}")
async def websocket_endpoint(websocket: WebSocket, room_code: str):
    await manager.connect(websocket, room_code)
    try:
        while True:
            data = await websocket.receive_text()
            payload = json.loads(data)
            action = payload.get("action")
            
            if action == "join":
                player_name = payload.get("name")
                if player_name not in manager.games[room_code]["players"]:
                    manager.games[room_code]["players"].append(player_name)
                    if not manager.games[room_code]["host"]:
                        manager.games[room_code]["host"] = player_name # First to join is host
                        
                await manager.broadcast({
                    "type": "lobby_update",
                    "players": manager.games[room_code]["players"],
                    "host": manager.games[room_code]["host"]
                }, room_code)
                
            elif action == "start":
                # Host starts the game. Payload should contain the challenge_id to fetch, or the full challenge object
                challenge_data = payload.get("challenge")
                manager.games[room_code]["challenge"] = challenge_data
                manager.games[room_code]["state"] = "playing"
                manager.games[room_code]["scores"] = {p: 0 for p in manager.games[room_code]["players"]}
                
                await manager.broadcast({
                    "type": "game_started",
                    "challenge": challenge_data
                }, room_code)
                
            elif action == "submit_answer":
                player = payload.get("player")
                answer_id = payload.get("answer_id")
                correct = payload.get("is_correct")
                
                if correct:
                    manager.games[room_code]["scores"][player] += 100
                    
                await manager.broadcast({
                    "type": "score_update",
                    "scores": manager.games[room_code]["scores"]
                }, room_code)
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_code)
        if room_code in manager.games:
            await manager.broadcast({
                "type": "lobby_update",
                "players": manager.games[room_code]["players"] # We don't remove names on DC for simplicity yet
            }, room_code)

@app.get("/simulation/start")
async def start_simulation():
    # Reset simulation state if needed
    simulation_generator.__init__() 
    return simulation_generator.get_current_state()

@app.post("/simulation/action")
async def perform_action(request: ActionRequest, background_tasks: BackgroundTasks):
    state = simulation_generator.process_action(request.action, request.inventory)
    
    # Pre-fetch assets based on potential next states (logic to be expanded)
    # Example: If user is likely to encounter a "Spy", start generating the spy animation
    if state.get("difficulty", 1) > 1.5:
        background_tasks.add_task(prefetch_assets, "Spy character looking suspicious")

    return state

@app.post("/assets/generate")
async def generate_asset(request: VideoGenerationRequest):
    """
    Trigger media generation. Returns a task ID.
    User/Frontend should poll for status.
    """
    try:
        task_id = asset_pipeline.generate_asset(request.prompt, request.image_url, request.type)
        if not task_id:
             raise HTTPException(status_code=500, detail="Failed to start video generation")
        return {"task_id": task_id, "status": "PENDING"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/assets/status/{task_id}")
async def get_asset_status(task_id: str):
    return asset_pipeline.check_status(task_id)

class SettingsRequest(BaseModel):
    groq_key: Optional[str] = None
    runway_key: Optional[str] = None
    pinecone_key: Optional[str] = None

@app.post("/settings/update")
async def update_settings(req: SettingsRequest):
    """
    Updates the .env file with new keys and reloads services.
    """
    env_path = ".env"
    
    # Read existing
    env_vars = {}
    if os.path.exists(env_path):
        with open(env_path, "r") as f:
            for line in f:
                if "=" in line:
                    k, v = line.strip().split("=", 1)
                    env_vars[k] = v
    
    # Update
    if req.groq_key:
        env_vars["GROQ_API_KEY"] = req.groq_key
        os.environ["GROQ_API_KEY"] = req.groq_key
    if req.runway_key:
        env_vars["RUNWAYML_API_SECRET"] = req.runway_key
        os.environ["RUNWAYML_API_SECRET"] = req.runway_key
    if req.pinecone_key:
        env_vars["PINECONE_API_KEY"] = req.pinecone_key
        os.environ["PINECONE_API_KEY"] = req.pinecone_key
        
    # Write back
    with open(env_path, "w") as f:
        for k, v in env_vars.items():
            f.write(f"{k}={v}\n")
            
    # Re-init services
    global simulation_generator, challenge_generator, asset_pipeline
    simulation_generator = SimulationGenerator()
    challenge_generator = ChallengeGenerator()
    asset_pipeline = AssetPipeline()
    
    return {"status": "updated", "message": "Keys saved. Core logic reloaded."}

def prefetch_assets(prompt: str):
    """
    Background task to generate assets ahead of time.
    """
    print(f"Prefetching asset for prompt: {prompt}")
    # In a real scenario, we'd have a base image ready or generate one first.
    # asset_pipeline.generate_video_from_image(prompt, "placeholder_url")
    pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
