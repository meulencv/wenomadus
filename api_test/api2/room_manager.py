import qrcode
from io import BytesIO
import base64
from sqlalchemy.orm import Session
from . import models

class RoomManager:
    def __init__(self, db_session):
        self.db_session = db_session
    
    def create_room(self, admin_id):
        """Create a new room with a unique code"""
        # Generate a unique code
        while True:
            code = models.Room.generate_room_code()
            existing = self.db_session.query(models.Room).filter_by(code=code).first()
            if not existing:
                break
        
        room = models.Room(code=code, admin_id=admin_id)
        self.db_session.add(room)
        self.db_session.commit()
        return room
    
    def get_room_by_code(self, code):
        """Get a room by its code"""
        return self.db_session.query(models.Room).filter_by(code=code).first()
    
    def add_participant(self, room_id, name):
        """Add a participant to a room"""
        participant = models.Participant(room_id=room_id, name=name)
        self.db_session.add(participant)
        self.db_session.commit()
        return participant
    
    def submit_responses(self, participant_id, responses):
        """Submit a participant's responses to questions"""
        participant = self.db_session.query(models.Participant).filter_by(id=participant_id).first()
        if not participant:
            return {"error": "Participant not found"}
        
        # Delete any existing responses from this participant
        self.db_session.query(models.Response).filter_by(participant_id=participant_id).delete()
        
        # Add new responses
        for question_id, answer in responses.items():
            response = models.Response(
                participant_id=participant_id,
                question_id=question_id,
                answer=answer
            )
            self.db_session.add(response)
        
        # Mark participant as completed
        participant.has_completed = True
        self.db_session.commit()
        
        # Check if all participants have completed
        room = participant.room
        all_completed = all(p.has_completed for p in room.participants)
        
        return {
            "success": True, 
            "all_completed": all_completed
        }
    
    def generate_qr_code(self, room_code, base_url="http://yourapp.com/join/"):
        """Generate a QR code for room invitation"""
        join_url = f"{base_url}{room_code}"
        
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(join_url)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        buffered = BytesIO()
        img.save(buffered)
        img_str = base64.b64encode(buffered.getvalue()).decode()
        
        return {
            "url": join_url,
            "qr_code_base64": img_str
        }
    
    def check_room_status(self, room_id):
        """Check if all participants have completed their responses"""
        room = self.db_session.query(models.Room).filter_by(id=room_id).first()
        if not room:
            return {"error": "Room not found"}
        
        return {
            "completed": all(p.has_completed for p in room.participants),
            "total_participants": len(room.participants),
            "completed_participants": sum(1 for p in room.participants if p.has_completed)
        }
