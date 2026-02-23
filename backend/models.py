from sqlalchemy import create_engine, Column, String, Integer, Text, Boolean
from sqlalchemy.orm import sessionmaker, declarative_base
import json
import uuid

Base = declarative_base()

class ChallengeModel(Base):
    __tablename__ = 'challenges'
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    topic = Column(String, nullable=False)
    difficulty = Column(String, nullable=False)
    scenario = Column(Text, nullable=False)
    options_json = Column(Text, nullable=False) # Store options array as a JSON string
    correct_option_id = Column(String, nullable=False)
    explanation = Column(Text, nullable=False)
    is_premium = Column(Boolean, default=False)
    
    def to_dict(self):
        return {
            "id": self.id,
            "title": f"Intelligence for All: {self.topic}",
            "scenario": self.scenario,
            "options": json.loads(self.options_json),
            "correct_option_id": self.correct_option_id,
            "explanation": self.explanation
        }

class UserModel(Base):
    __tablename__ = 'users'
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String, unique=True, index=True, nullable=False)
    balance = Column(Integer, default=0) # using integer for whole number amounts like $10
    games_played = Column(Integer, default=0)
    
    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "balance": self.balance,
            "games_played": self.games_played
        }

# SQLite Database Setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./omnimind.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def init_db():
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
