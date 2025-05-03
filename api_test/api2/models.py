import random
import string
import json
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from . import config

Base = declarative_base()

class Room(Base):
    __tablename__ = 'rooms'
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    code = Column(String(config.ROOM_CODE_LENGTH), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    admin_id = Column(String(36), nullable=False)
    is_completed = Column(Boolean, default=False)
    recommended_destination = Column(String(255), nullable=True)
    
    participants = relationship("Participant", back_populates="room")
    
    @classmethod
    def generate_room_code(cls):
        """Generate a random room code"""
        return ''.join(random.choices(string.ascii_uppercase + string.digits, k=config.ROOM_CODE_LENGTH))
    
    def to_dict(self):
        return {
            "id": self.id,
            "code": self.code,
            "created_at": self.created_at.isoformat(),
            "admin_id": self.admin_id,
            "is_completed": self.is_completed,
            "recommended_destination": self.recommended_destination,
            "participant_count": len(self.participants)
        }


class Participant(Base):
    __tablename__ = 'participants'
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    room_id = Column(String(36), ForeignKey('rooms.id'))
    name = Column(String(255), nullable=False)
    has_completed = Column(Boolean, default=False)
    joined_at = Column(DateTime, default=datetime.utcnow)
    
    room = relationship("Room", back_populates="participants")
    responses = relationship("Response", back_populates="participant")
    
    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "has_completed": self.has_completed,
            "joined_at": self.joined_at.isoformat()
        }


class Question(Base):
    __tablename__ = 'questions'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    text = Column(Text, nullable=False)
    category = Column(String(50), nullable=False)  # e.g., 'beach', 'mountain', 'budget', etc.
    
    responses = relationship("Response", back_populates="question")
    
    def to_dict(self):
        return {
            "id": self.id,
            "text": self.text,
            "category": self.category
        }


class Response(Base):
    __tablename__ = 'responses'
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    participant_id = Column(String(36), ForeignKey('participants.id'))
    question_id = Column(Integer, ForeignKey('questions.id'))
    answer = Column(Boolean, nullable=False)  # True for Yes, False for No
    
    participant = relationship("Participant", back_populates="responses")
    question = relationship("Question", back_populates="responses")
    
    def to_dict(self):
        return {
            "id": self.id,
            "participant_id": self.participant_id,
            "question_id": self.question_id,
            "answer": self.answer
        }


class Destination(Base):
    __tablename__ = 'destinations'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    iata_code = Column(String(3), nullable=True)  # Airport or city code
    country = Column(String(100), nullable=False)
    attributes = Column(Text, nullable=False)  # JSON string of destination attributes
    
    def get_attributes(self):
        return json.loads(self.attributes)
    
    def set_attributes(self, attrs_dict):
        self.attributes = json.dumps(attrs_dict)
    
    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "iata_code": self.iata_code,
            "country": self.country,
            "attributes": self.get_attributes()
        }
