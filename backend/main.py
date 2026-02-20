from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from asset_pipeline import AssetPipeline
from simulation_generator import SimulationGenerator
import os

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

@app.get("/play", response_class=HTMLResponse)
async def play():
    with open("static/index.html") as f:
        return f.read()

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

# Endpoints

@app.get("/")
async def root():
    return {"message": "OGCHALLENGE Core Online"}

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
async def generate_challenge_endpoint(req: ChallengeRequest):
    return challenge_generator.generate_challenge(req.topic, req.difficulty, req.is_premium)

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
    Trigger video generation. Returns a task ID.
    User/Frontend should poll for status.
    """
    try:
        task_id = asset_pipeline.generate_video_from_image(request.prompt, request.image_url)
        if not task_id:
             raise HTTPException(status_code=500, detail="Failed to start video generation")
        return {"task_id": task_id, "status": "PENDING"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/assets/status/{task_id}")
async def get_asset_status(task_id: str):
    return asset_pipeline.check_status(task_id)

class SettingsRequest(BaseModel):
    openai_key: Optional[str] = None
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
    if req.openai_key:
        env_vars["OPENAI_API_KEY"] = req.openai_key
        os.environ["OPENAI_API_KEY"] = req.openai_key
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
    global simulation_generator, challenge_generator
    simulation_generator = SimulationGenerator()
    challenge_generator = ChallengeGenerator()
    
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
