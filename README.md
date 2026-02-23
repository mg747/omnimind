# OmniMind: Cinematic AI Simulation Platform

**Version:** MVP (Alpha)
**Architecture:** Python (FastAPI/LangChain) + Flutter (Dart)

## Status: Code Complete, Environment Setup Required

The core architecture, logic engine, and asset pipeline are implemented. However, since the `flutter` CLI was not available in the environment during creation, the project requires initialization on your machine.

## 🚀 Activation Guide

### 1. Prerequisites
- **Python 3.8+**
- **Flutter SDK** (Install from [flutter.dev](https://flutter.dev))
- **API Keys**:
    - OpenAI API Key (Logic)
    - RunwayML API Secret (Video Assets)
    - Pinecone API Key (Memory)

### 2. Backend Setup (The "Brain")
The backend is ready to run.

```bash
cd omnimind/backend
# Create .env file with your keys
echo "OPENAI_API_KEY=sk-..." >> .env
echo "RUNWAYML_API_SECRET=..." >> .env
echo "PINECONE_API_KEY=..." >> .env

# Activate and Run
source venv/bin/activate
uvicorn main:app --reload
```
*Verify at `http://localhost:8000`*

### 3. Frontend Setup (The "Body")
Because `flutter create` could not be run, you must initialize the platform infrastructure:

```bash
cd omnimind/frontend

# 1. Initialize Flutter infrastructure (Android/iOS/Web folders)
# This command usually respects existing files, but back up lib/ just in case.
flutter create . 

# 2. Get dependencies
flutter pub get

# 3. Run the App
flutter run
```

## 📂 Project Structure
- `backend/simulation_generator.py`: **LangChain Agent** bridging Narrative <-> Assets.
- `backend/asset_pipeline.py`: **Runway Gen-3 Integration** with JSON caching.
- `frontend/lib/services/api_service.dart`: **Bridge** connecting UI to Backend.
- `frontend/lib/widgets/holographic_display.dart`: **Smart Video Widget** with caching.

## 🛠 Troubleshooting
- **"Asset Generation Failed"**: ensure you have valid credits in RunwayML.
- **"LLM Offline"**: check `OPENAI_API_KEY` in `backend/.env`.
- **"Connection Refused"**: Ensure `api_service.dart` points to the correct IP (`localhost` vs `10.0.2.2` for Android).
## OmniMind Update
The application has been successfully updated to "Intelligence for All". Cloud AI parsing (Groq) and Memory Context Retrieval (Pinecone) are actively supporting the backend simulation generation!
