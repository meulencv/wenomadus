"""
Complete example of using the Gemini API for travel recommendations
"""

from gemini import GeminiAPI
from travel_questions import TRAVEL_QUESTIONS, create_response_format
import json

def get_console_answers():
    """Asks the user for answers via console"""
    print("Answer the following questions with 'yes' or 'no':")
    answers = []
    
    for idx, question in enumerate(TRAVEL_QUESTIONS, 1):
        while True:
            answer = input(f"{idx}. {question} (yes/no): ").lower().strip()
            if answer in ["yes", "y"]:
                answers.append("yes")
                break
            elif answer in ["no", "n"]:
                answers.append("no")
                break
            else:
                print("Please answer 'yes' or 'no'.")
    
    return answers

def save_recommendation(recommendation, filename="travel_recommendation.json"):
    """Saves the recommendation to a JSON file"""
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(recommendation, f, indent=2)
    print(f"\nRecommendation saved to '{filename}'")

def load_answers(filename):
    """Loads answers from a JSON file"""
    with open(filename, 'r', encoding='utf-8') as f:
        return json.load(f)

def main():
    print("=== TRAVEL RECOMMENDATION SYSTEM ===\n")
    
    mode = input("How would you like to provide answers?\n"
                "1. Answer questions now\n"
                "2. Load from a JSON file\n"
                "Select (1/2): ")
                
    if mode == "1":
        # Get answers from user
        answers = get_console_answers()
        api_data = create_response_format(answers)
        
        # Optionally save the answers
        if input("\nDo you want to save your answers? (y/n): ").lower().startswith('y'):
            filename = input("Filename (answers.json): ") or "answers.json"
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(api_data, f, indent=2)
            print(f"Answers saved to '{filename}'")
    
    elif mode == "2":
        # Load answers from file
        filename = input("Enter the JSON filename: ")
        api_data = load_answers(filename)
    
    else:
        print("Invalid option. Exiting.")
        return
        
    # Generate recommendation
    print("\nGenerating travel recommendation...")
    gemini = GeminiAPI()
    recommendation = gemini.get_travel_recommendation(api_data)
    
    # Show recommendation
    print("\n=== TRAVEL RECOMMENDATION ===")
    print(f"\nRecommended destination: {recommendation['main_destination']['name']}, {recommendation['main_destination']['country']}")
    print(f"Description: {recommendation['main_destination']['description']}")
    print(f"Best time to visit: {recommendation['main_destination']['best_time_to_visit']}")
    
    print("\nPlaces of interest:")
    for place in recommendation['places_of_interest']:
        print(f"- {place['name']} ({place['type']}): {place['description']}")
    
    print("\nAlternative destinations:")
    for destination in recommendation['alternative_destinations']:
        print(f"- {destination['name']}, {destination['country']}: {destination['reason']}")
    
    print("\nTravel tips:")
    for idx, tip in enumerate(recommendation['travel_tips'], 1):
        print(f"{idx}. {tip}")
    
    # Save recommendation to file
    if input("\nDo you want to save this recommendation? (y/n): ").lower().startswith('y'):
        filename = input("Filename (recommendation.json): ") or "recommendation.json"
        save_recommendation(recommendation, filename)

if __name__ == "__main__":
    main()
