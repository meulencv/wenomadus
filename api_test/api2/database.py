from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session
from .models import Base
from . import config

# Create database engine
engine = create_engine(config.DATABASE_URL)

# Create session factory
session_factory = sessionmaker(bind=engine)
Session = scoped_session(session_factory)

def init_db():
    """Initialize database tables"""
    Base.metadata.create_all(engine)

def get_session():
    """Get a database session"""
    return Session()

def close_session(session):
    """Close a database session"""
    session.close()
