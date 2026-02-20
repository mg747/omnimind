from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.schema.output_parser import StrOutputParser
from database import Database
from typing import Dict, List
import json
import os

class SimulationGenerator:
    def __init__(self):
        self.db = Database()
        # Initialize LLM only if key is present
        api_key = os.getenv("OPENAI_API_KEY")
        if api_key:
            self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0.7)
        else:
            print("Warning: OPENAI_API_KEY not set. Using fallback logic.")
            self.llm = None
        
        self.session_id = "demo_session" # In prod, this would be dynamic

    def process_action(self, action: str, inventory: List[str]) -> Dict:
        """
        Generates the next narrative node using LangChain + RAG.
        """
        # 1. Retrieve Context
        context = self.db.retrieve_context(self.session_id, action)

        # 2. Construct Prompt
        if self.llm:
            prompt = ChatPromptTemplate.from_template("""
                You are the Director AI for a sci-fi thriller game.
                
                Context from previous events:
                {context}
                
                Current Inventory: {inventory}
                
                User Action: {action}
                
                Task: Generate the next narrative segment. 
                If the user finds an item, describe it visually so we can generate a hologram.
                
                Output JSON format:
                {{
                    "message": "Startling narrative description...",
                    "options": ["Option 1", "Option 2"],
                    "difficulty_score": 1.5,
                    "assets": [
                        {{ "type": "video", "prompt": "3D render of [item], rotating, cinematic lighting" }}
                    ]
                }}
            """)
            
            chain = prompt | self.llm | StrOutputParser()
            
            try:
                response_str = chain.invoke({
                    "context": context,
                    "inventory": ", ".join(inventory),
                    "action": action
                })
                # Parse JSON (robustness needed here in prod)
                # Removing markdown code blocks if present
                clean_json = response_str.replace("```json", "").replace("```", "").strip()
                result = json.loads(clean_json)
                
                # Save new memory
                self.db.save_memory(self.session_id, f"Action: {action} -> Result: {result['message']}")
                
                return result
            except Exception as e:
                print(f"LLM Error: {e}")
                return self._fallback_logic(action)
        else:
            return self._fallback_logic(action)

    def _fallback_logic(self, action: str) -> Dict:
        # Simple fallback if no LLM
        return {
            "message": f"You performed: {action}. (LLM Offline)",
            "options": ["Continue"],
            "difficulty_score": 1.0,
            "assets": []
        }

    def get_current_state(self) -> Dict:
        # Initial state
        return {
             "message": "System Online. Awaiting input.",
             "options": ["Look around"],
             "difficulty_score": 1,
             "assets": []
        }
