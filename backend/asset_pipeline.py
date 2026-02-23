import os
import time
import requests
import json
import hashlib
from typing import Optional, Dict

class AssetPipeline:
    def __init__(self):
        self.api_key = os.getenv("RUNWAYML_API_SECRET")
        self.base_url = "https://api.dev.runwayml.com/v1"
        self.cache_file = "asset_cache.json"
        self._load_cache()

    def _load_cache(self):
        if os.path.exists(self.cache_file):
            with open(self.cache_file, 'r') as f:
                self.cache = json.load(f)
        else:
            self.cache = {}

    def _save_cache(self):
        with open(self.cache_file, 'w') as f:
            json.dump(self.cache, f)

    def _get_headers(self):
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "X-Runway-Version": "2024-11-06"
        }

    def generate_video_from_image(self, prompt: str, image_url: str) -> str:
        """
        Generates a video from an image using Runway Gen-3 Alpha Turbo.
        """
        if not self.api_key:
            print("Mocking generation (No API Key)")
            return "mock_task_id"

        # Hash the prompt and image URL to create a unique key
        cache_key = hashlib.sha256(f"{prompt}_{image_url}".encode()).hexdigest()
        
        if cache_key in self.cache:
            print(f"Cache hit for prompt: {prompt}")
            return self.cache[cache_key]['task_id']

        payload = {
            "promptText": prompt,
            "model": "gen3a_turbo",
            "watermark": False
        }
        
        endpoint = "text_to_video"
        if image_url and image_url != "placeholder":
            payload["promptImage"] = image_url
            endpoint = "image_to_video"

        try:
            response = requests.post(
                f"{self.base_url}/{endpoint}",
                headers=self._get_headers(),
                json=payload
            )
            response.raise_for_status()
        except requests.exceptions.RequestException as e:
            error_data = e.response.json() if e.response else {}
            if "credits" in str(error_data.get("error", "")).lower():
                print("RunwayML Error: Out of Credits")
                return "out_of_credits"
            print(f"Error generating video: {e} - {error_data}")
            return "error_task_id"

        data = response.json()
        task_id = data.get("id")
        
        # Update cache
        self.cache[cache_key] = {'task_id': task_id, 'prompt': prompt, 'status': 'PENDING'}
        self._save_cache()
        
        return task_id

    def check_status(self, task_id: str) -> Dict:
        if task_id == "mock_task_id":
             return {"status": "SUCCEEDED", "output": ["https://assets.runwayml.com/example.webm"]}

        try:
            response = requests.get(
                f"{self.base_url}/tasks/{task_id}",
                headers=self._get_headers()
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"status": "FAILED", "error": str(e)}

