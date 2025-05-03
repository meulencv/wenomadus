from collections import defaultdict
from datetime import datetime, timedelta
from sqlalchemy import func
from . import models
from .skyscanner_api import SkyscannerApiClient

class RecommendationEngine:
    def __init__(self, db_session):
        self.db_session = db_session
        self.skyscanner_client = SkyscannerApiClient()
    
    def analyze_room_responses(self, room_id):
        """Analyze responses from all participants in a room"""
        room = self.db_session.query(models.Room).filter_by(id=room_id).first()
        if not room:
            return {"error": "Room not found"}
        
        # Get all participants in the room
        participants = room.participants
        if not participants:
            return {"error": "No participants found in room"}
        
        # Get all responses from all participants
        participant_ids = [p.id for p in participants]
        all_responses = self.db_session.query(models.Response).filter(
            models.Response.participant_id.in_(participant_ids)
        ).all()
        
        # Group responses by question
        question_responses = defaultdict(list)
        for response in all_responses:
            question_responses[response.question_id].append(response.answer)
        
        # Find questions where everyone answered 'Yes'
        common_yes_questions = []
        for question_id, answers in question_responses.items():
            if len(answers) == len(participants) and all(answers):
                common_yes_questions.append(question_id)
        
        # Get the question details for the common 'Yes' questions
        common_questions = self.db_session.query(models.Question).filter(
            models.Question.id.in_(common_yes_questions)
        ).all()
        
        # Group common questions by category
        category_counts = defaultdict(int)
        for question in common_questions:
            category_counts[question.category] += 1
        
        return {
            "common_yes_questions": [q.to_dict() for q in common_questions],
            "category_preferences": dict(category_counts)
        }
    
    def find_matching_destinations(self, category_preferences):
        """Find destinations that match the category preferences"""
        # In a real application, you would have a more sophisticated matching algorithm
        # This is a simplified example
        destinations = self.db_session.query(models.Destination).all()
        
        matches = []
        for destination in destinations:
            dest_attrs = destination.get_attributes()
            match_score = 0
            
            for category, count in category_preferences.items():
                if category in dest_attrs and dest_attrs[category]:
                    match_score += count
            
            if match_score > 0:
                matches.append({
                    "destination": destination.to_dict(),
                    "score": match_score
                })
        
        # Sort by score descending
        matches.sort(key=lambda x: x["score"], reverse=True)
        return matches[:5]  # Top 5 matches
    
    def recommend_destination(self, room_id):
        """Generate a destination recommendation for a room"""
        # Analyze responses
        analysis = self.analyze_room_responses(room_id)
        if "error" in analysis:
            return analysis
        
        # Find matching destinations
        matches = self.find_matching_destinations(analysis["category_preferences"])
        if not matches:
            return {"error": "No matching destinations found"}
        
        # Get the top match
        top_match = matches[0]["destination"]
        
        # Update the room with the recommended destination
        room = self.db_session.query(models.Room).filter_by(id=room_id).first()
        room.recommended_destination = top_match["name"]
        room.is_completed = True
        self.db_session.commit()
        
        # Find flights to this destination (if it has an IATA code)
        flights_info = {}
        if top_match.get("iata_code"):
            # In a real application, you would determine the origin dynamically
            # This is just an example with a hardcoded origin
            origin = "MAD"  # Madrid
            destination = top_match["iata_code"]
            
            # Search flights for a month from now (as an example)
            future_date = (datetime.now() + timedelta(days=30)).strftime("%Y-%m-%d")
            flights = self.skyscanner_client.complete_search(origin, destination, future_date)
            
            if "error" not in flights:
                flights_info = flights
        
        return {
            "destination": top_match,
            "category_matches": analysis["category_preferences"],
            "flights": flights_info,
            "other_recommendations": [m["destination"] for m in matches[1:]]
        }
    
    def load_sample_questions(self):
        """Load sample questions for testing"""
        sample_questions = [
            {"text": "¿Te gustan los destinos con playa?", "category": "beach"},
            {"text": "¿Prefieres destinos con montaña?", "category": "mountain"},
            {"text": "¿Te interesa visitar museos?", "category": "culture"},
            {"text": "¿Te gusta la gastronomía local?", "category": "food"},
            {"text": "¿Buscas un destino económico?", "category": "budget"},
            {"text": "¿Prefieres un clima cálido?", "category": "warm_climate"},
            {"text": "¿Te gustan las actividades al aire libre?", "category": "outdoors"},
            {"text": "¿Prefieres destinos urbanos?", "category": "urban"},
            {"text": "¿Te interesa el turismo histórico?", "category": "history"},
            {"text": "¿Te gustaría un destino con vida nocturna?", "category": "nightlife"},
            {"text": "¿Es importante que haya buenas opciones de transporte público?", "category": "transport"},
            {"text": "¿Te interesan destinos con parques temáticos?", "category": "theme_parks"},
            {"text": "¿Prefieres un destino con poca aglomeración de turistas?", "category": "low_tourism"},
            {"text": "¿Te gustan los deportes acuáticos?", "category": "water_sports"},
            {"text": "¿Es importante que sea un destino familiar?", "category": "family"},
            {"text": "¿Buscas un destino romántico?", "category": "romantic"},
            {"text": "¿Te interesan las compras?", "category": "shopping"},
            {"text": "¿Prefieres un destino con actividades de aventura?", "category": "adventure"},
            {"text": "¿Te gustaría un destino con buenas opciones de relax?", "category": "relaxation"},
            {"text": "¿Es importante la sostenibilidad del destino?", "category": "sustainability"},
            {"text": "¿Prefieres destinos en Europa?", "category": "europe"},
            {"text": "¿Te interesa viajar a Asia?", "category": "asia"},
            {"text": "¿Consideras América como destino?", "category": "americas"},
            {"text": "¿Te gustaría viajar a un destino exótico?", "category": "exotic"},
            {"text": "¿Prefieres destinos donde sea fácil comunicarse en español?", "category": "spanish_language"},
        ]
        
        for q_data in sample_questions:
            existing = self.db_session.query(models.Question).filter_by(text=q_data["text"]).first()
            if not existing:
                question = models.Question(text=q_data["text"], category=q_data["category"])
                self.db_session.add(question)
        
        self.db_session.commit()
        return {"success": True, "count": len(sample_questions)}
    
    def load_sample_destinations(self):
        """Load sample destinations for testing"""
        sample_destinations = [
            {
                "name": "Barcelona",
                "iata_code": "BCN",
                "country": "España",
                "attributes": {
                    "beach": True,
                    "urban": True,
                    "culture": True,
                    "food": True,
                    "history": True,
                    "nightlife": True,
                    "transport": True,
                    "shopping": True,
                    "europe": True,
                    "spanish_language": True
                }
            },
            {
                "name": "París",
                "iata_code": "CDG",
                "country": "Francia",
                "attributes": {
                    "urban": True,
                    "culture": True,
                    "food": True,
                    "history": True,
                    "romantic": True,
                    "transport": True,
                    "shopping": True,
                    "europe": True
                }
            },
            # Add more destinations as needed
        ]
        
        for d_data in sample_destinations:
            existing = self.db_session.query(models.Destination).filter_by(name=d_data["name"]).first()
            if not existing:
                dest = models.Destination(
                    name=d_data["name"],
                    iata_code=d_data["iata_code"],
                    country=d_data["country"],
                    attributes="{}"
                )
                dest.set_attributes(d_data["attributes"])
                self.db_session.add(dest)
        
        self.db_session.commit()
        return {"success": True, "count": len(sample_destinations)}
