"""
Complete list of 25 yes/no questions for the travel destination selection application
"""

TRAVEL_QUESTIONS = [
    "Do you want a relaxing vacation?",
    "Are you interested in cultural experiences?",
    "Do you prefer to travel internationally?",
    "Do you want a short trip (less than 7 days)?",
    "Would you mind flying more than 5 hours?",
    "Would you be willing to stay in a hostel to save money?",
    "Are you looking for a family-friendly trip?",
    "Are you looking for a romantic getaway?",
    "Are you interested in destinations with historical significance?",
    "Do you prefer destinations with warm weather?",
    "Do you like adventure activities (hiking, water sports, etc.)?",
    "Is visiting beaches important to you?",
    "Do you prefer urban destinations over rural ones?",
    "Do you have a tight budget for this trip?",
    "Is local cuisine an important part of the trip for you?",
    "Do you prefer popular tourist destinations?",
    "Would you like to visit museums and art galleries?",
    "Are you looking for destinations with active nightlife?",
    "Is it important for you to be able to communicate in your native language?",
    "Do you prefer all-inclusive resort accommodations?",
    "Would you like a destination where you can go shopping?",
    "Would you avoid traveling during high season to avoid crowds?",
    "Is it important that the destination has good public transportation?",
    "Do you prefer destinations considered safe for tourists?",
    "Would you be interested in a destination that promotes sustainable tourism?"
]

def create_response_format(answers):
    """
    Creates JSON format to send to the Gemini API
    
    Args:
        answers (list): List of "yes" or "no" answers for each question
        
    Returns:
        list: List of dictionaries with {question, answer} format
    """
    if len(answers) != len(TRAVEL_QUESTIONS):
        raise ValueError(f"Expected {len(TRAVEL_QUESTIONS)} answers, received {len(answers)}")
    
    return [
        {"question": question, "answer": answer}
        for question, answer in zip(TRAVEL_QUESTIONS, answers)
    ]

# Example usage
if __name__ == "__main__":
    # Example with random answers
    import random
    
    # Generate random answers (yes/no)
    sample_answers = ["yes" if random.choice([True, False]) else "no" for _ in TRAVEL_QUESTIONS]
    
    # Convert to JSON format for the API
    json_format = create_response_format(sample_answers)
    
    print("Example of JSON format to send to the API:")
    import json
    print(json.dumps(json_format, indent=2))
