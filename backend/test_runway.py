from asset_pipeline import AssetPipeline
from dotenv import load_dotenv

load_dotenv()
pipeline = AssetPipeline()
task_id = pipeline.generate_video_from_image("A futuristic city", "placeholder")
print(f"Task ID: {task_id}")
