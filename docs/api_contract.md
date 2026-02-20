# OmniMind API Contract

## Base URL
`http://localhost:8000` (Dev)

## 1. Simulation APIs
Connect the Frontend to the Director Logic.

### Start Simulation
- **Endpoint**: `POST /simulation/start`
- **Description**: Initializes a new session or loads an existing one.
- **Response**:
  ```json
  {
    "session_id": "uuid",
    "current_state": {
      "message": "You are in a dark room...",
      "options": ["Look left", "Check inventory"],
      "background_visual": "void_loop"
    }
  }
  ```

### Perform Action
- **Endpoint**: `POST /simulation/action`
- **Body**:
  ```json
  {
    "session_id": "uuid",
    "action": "Pick up the glowing key",
    "context": "User is looking at the table"
  }
  ```
- **Response**:
  ```json
  {
    "message": "The key feels warm. You picked it up.",
    "new_inventory": ["glowing_key"],
    "assets_to_display": [
      {
        "type": "video",
        "url": "http://.../assets/key_rotate.webm",
        "loop": true
      }
    ],
    "difficulty_score": 1.2
  }
  ```

## 2. Asset APIs
Manage the "Holographic" content.

### Check Asset Status
- **Endpoint**: `GET /assets/status/{task_id}`
- **Description**: Polling endpoint for long-running video generation.
- **Response**:
  ```json
  {
    "status": "SUCCEEDED", // PENDING, FAILED
    "progress": 100,
    "url": "https://..."
  }
  ```

### Pre-Fetch Trigger (Internal/Optimization)
- **Endpoint**: `POST /assets/prefetch`
- **Description**: Triggered by logic engine to prepare assets for *likely* future nodes.

## 3. Integration Plan
- **Frontend**: Use `Dio` for requests. Implement a `AssetManager` class that polls the status endpoint if an asset is not ready immediately.
- **Backend**: Use `BackgroundTasks` in FastAPI to handle generation without blocking the simulation response.
