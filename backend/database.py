class Database:
    def __init__(self):
        self.memory = {}

    def retrieve_context(self, session_id: str, action: str) -> str:
        return "\n".join(self.memory.get(session_id, []))

    def save_memory(self, session_id: str, memory_string: str):
        if session_id not in self.memory:
            self.memory[session_id] = []
        self.memory[session_id].append(memory_string)