import os
import time
from typing import List, Dict, Optional
from pinecone import Pinecone, ServerlessSpec
from langchain_pinecone import PineconeEmbeddings

class Database:
    def __init__(self):
        self.api_key = os.getenv("PINECONE_API_KEY")
        self.env = os.getenv("PINECONE_ENV", "us-east-1")
        self.index_name = "omnimind-memory-pinecone" # New index for 1024 dimensions
        
        if self.api_key:
            try:
                self.pc = Pinecone(api_key=self.api_key)
                self._initialize_index()
                self.index = self.pc.Index(self.index_name)
            except Exception as e:
                print(f"Pinecone initialization failed: {e}. Running in stateless mode.")
                self.index = None
        else:
            print("Warning: PINECONE_API_KEY not set. Running in stateless mode.")
            self.index = None
            
    def _get_embeddings(self):
        # Lazy load to avoid "no running event loop" at startup time
        if not hasattr(self, '_embeddings'):
            self._embeddings = PineconeEmbeddings(model="multilingual-e5-large", pinecone_api_key=self.api_key)
        return self._embeddings

    def _initialize_index(self):
        """
        Creates the Pinecone index if it doesn't exist.
        """
        existing_indexes = [i.name for i in self.pc.list_indexes()]
        if self.index_name not in existing_indexes:
            self.pc.create_index(
                name=self.index_name,
                dimension=1024, # Pinecone multilingual-e5-large embedding dimension
                metric="cosine",
                spec=ServerlessSpec(cloud="aws", region=self.env)
            )
            while not self.pc.describe_index(self.index_name).status['ready']:
                time.sleep(1)

    def save_memory(self, session_id: str, text: str):
        """
        Embeds and saves a narrative snippet to Pinecone.
        """
        if not self.index: return

        vector = self._get_embeddings().embed_query(text)
        self.index.upsert(vectors=[(
            f"{session_id}_{int(time.time())}",
            vector,
            {"text": text, "session_id": session_id}
        )])

    def retrieve_context(self, session_id: str, query: str, k: int = 3) -> str:
        """
        Retrieves relevant past narrative context.
        """
        if not self.index: return ""

        vector = self._get_embeddings().embed_query(query)
        results = self.index.query(
            vector=vector,
            top_k=k,
            filter={"session_id": session_id},
            include_metadata=True
        )

        context_list = [match['metadata']['text'] for match in results['matches']]
        return "\n".join(context_list)
