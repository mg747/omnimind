from langchain_groq import ChatGroq
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
import json
import os
import random
import re

class ChallengeGenerator:
    def __init__(self):
        # Groq Cloud API integration
        api_key = os.getenv("GROQ_API_KEY")
        if api_key:
            self.llm = ChatGroq(model="llama-3.1-8b-instant", temperature=0.8, model_kwargs={"response_format": {"type": "json_object"}})
        else:
            print("Warning: GROQ_API_KEY not set.")
            self.llm = None

    def generate_challenge(self, topic, difficulty: str, is_premium: bool = False, count: int = 1):
        if not self.llm:
            return self._fallback_challenge(topic if isinstance(topic, str) else ", ".join(topic), count)
            
        if isinstance(topic, list):
            topics_prompt = f"a diverse mix of the following topics: {', '.join(topic)}"
        else:
            topics_prompt = topic
            if topic == "All Categories":
                topics_prompt = "a diverse mix of random intellectual topics (e.g. Science, Future Tech, History, Philosophy, Pop Culture)"

        prompt = ChatPromptTemplate.from_template("""
            Generate {count} unique, engaging, and intellectual challenges for the topic/theme: "{topic}".
            Difficulty Level: {difficulty}
            Type: Multiple Choice / Situational Puzzle

            The user is playing "OGCHALLENGE", a game for critical thinking.
            
            Output strictly a valid JSON object with a key "challenges" containing an array of objects. DO NOT wrap it in markdown:
            {{
                "challenges": [
                    {{
                        "id": "unique_id_1",
                        "title": "Creative Title 1",
                        "scenario": "Detailed scenario or question text...",
                        "options": [
                            {{ "id": "A", "text": "Option A text" }},
                            {{ "id": "B", "text": "Option B text" }},
                            {{ "id": "C", "text": "Option C text" }},
                            {{ "id": "D", "text": "Option D text" }}
                        ],
                        "correct_option_id": "A",
                        "explanation": "Detailed explanation of why A is correct and others are wrong."
                    }}
                ]
            }}
        """)

        chain = prompt | self.llm | StrOutputParser()
        
        try:
            response = chain.invoke({"topic": topics_prompt, "difficulty": difficulty, "count": count})
            clean_json = response.strip()
            # If the LLM still returns markdown blocks for some reason, remove them
            if clean_json.startswith("```"):
                clean_json = re.sub(r"^```(?:json)?\n|\n```$", "", clean_json)
                
            parsed = json.loads(clean_json)
            challenges = parsed.get("challenges", [])
            
            # Ensure we always return a list
            if not isinstance(challenges, list):
                challenges = [challenges]
                
            time_limits = {"Beginner": 60, "Medium": 60, "Hard": 120, "Expert": 180}
            default_limit = time_limits.get(difficulty, 60)
            import uuid
            for c in challenges:
                c["time_limit"] = default_limit
                c["id"] = f"challenge_{uuid.uuid4().hex[:8]}"
                
            return challenges[:count] # Enforce count
        except Exception as e:
            print(f"Error generating challenge: {e}")
            return self._fallback_challenge(topic, count, error=str(e))

    def _fallback_challenge(self, topic, count, error=None):
        import uuid
        fallbacks = []
        for i in range(count):
            err_msg = f" Error Details: {error}" if error else ""
            fallbacks.append({
                "id": f"fallback_{uuid.uuid4().hex[:8]}",
                "title": f"Offline Challenge: {topic}",
                "scenario": f"The AI Core is currently offline or encountered an error. Please check your API Key.{err_msg}",
                "options": [
                    { "id": "A", "text": "I will check the logs." },
                    { "id": "B", "text": "I will continue in offline mode." }
                ],
                "correct_option_id": "A",
                "explanation": f"System failed to generate content.{err_msg}",
                "time_limit": 60
            })
        return fallbacks
