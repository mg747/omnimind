from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.schema.output_parser import StrOutputParser
import json
import os
import random

class ChallengeGenerator:
    def __init__(self):
        api_key = os.getenv("OPENAI_API_KEY")
        if api_key:
            self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0.8)
        else:
            self.llm = None

    def generate_challenge(self, topic: str, difficulty: str, is_premium: bool = False):
        if not self.llm:
            return self._fallback_challenge(topic)

        prompt = ChatPromptTemplate.from_template("""
            Generate a unique, engaging, and intellectual challenge for the topic: "{topic}".
            Difficulty Level: {difficulty}
            Type: Multiple Choice / Situational Puzzle

            The user is playing "OGCHALLENGE", a game for critical thinking.
            
            Output strictly valid JSON:
            {{
                "id": "unique_id",
                "title": "Creative Title",
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
        """)

        chain = prompt | self.llm | StrOutputParser()
        
        try:
            response = chain.invoke({"topic": topic, "difficulty": difficulty})
            clean_json = response.replace("```json", "").replace("```", "").strip()
            return json.loads(clean_json)
        except Exception as e:
            print(f"Error generating challenge: {e}")
            return self._fallback_challenge(topic)

    def _fallback_challenge(self, topic):
        return {
            "id": "fallback_01",
            "title": f"Offline Challenge: {topic}",
            "scenario": "The AI Core is currently offline. Please add your API Key to the backend/.env file to unlock infinite generation.",
            "options": [
                { "id": "A", "text": "I will add the key now." },
                { "id": "B", "text": "I will continue in offline mode." }
            ],
            "correct_option_id": "A",
            "explanation": "Without the API Key, the system cannot generate novel content."
        }
