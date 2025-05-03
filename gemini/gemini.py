from api import API_KEY
import requests
import json

class GeminiAPI:
    """Class for interacting with the Gemini API"""
    
    def __init__(self):
        self.api_key = API_KEY
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models"
        self.model = "gemini-2.0-flash"
    
    def generate_text(self, prompt, max_tokens=1024, temperature=0.7):
        """
        Generates text from a prompt using the Gemini API
        
        Args:
            prompt (str): The input text to generate content
            max_tokens (int): Maximum number of tokens to generate
            temperature (float): Controls randomness (0.0-1.0)
            
        Returns:
            str: Generated text
        """
        url = f"{self.base_url}/{self.model}:generateContent?key={self.api_key}"
        
        payload = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }],
            "generationConfig": {
                "maxOutputTokens": max_tokens,
                "temperature": temperature
            }
        }
        
        headers = {"Content-Type": "application/json"}
        
        try:
            response = requests.post(url, headers=headers, data=json.dumps(payload))
            response.raise_for_status()  # Raise exception for HTTP errors
            
            result = response.json()
            if 'candidates' in result and result['candidates']:
                return result['candidates'][0]['content']['parts'][0]['text']
            else:
                return "Could not generate text. Response: " + str(result)
                
        except Exception as e:
            return f"Error calling the API: {str(e)}"
    
    def get_travel_recommendation(self, answers, max_tokens=2048, temperature=0.4):
        """
        Generates travel recommendations based on yes/no question answers
        
        Args:
            answers (list): List of dictionaries with 'question' and 'answer' (yes/no)
            max_tokens (int): Maximum number of tokens for the response
            temperature (float): Controls creativity in the response
            
        Returns:
            dict: Structured JSON with travel recommendations
        """
        # Create prompt for the API
        prompt = "Based on the following travel preferences, generate recommendations for destinations:\n\n"
        for item in answers:
            prompt += f"- {item['question']}: {item['answer']}\n"
            
        prompt += "\nPlease return a JSON with exactly the following format:\n"
        prompt += """{
  "main_destination": {
    "name": "Destination name",
    "country": "Country",
    "description": "Brief description of the destination and why it fits the preferences",
    "best_time_to_visit": "Recommended season"
  },
  "places_of_interest": [
    {
      "name": "Place name",
      "type": "museum/square/monument/nature/etc",
      "description": "Brief description"
    }
  ],
  "alternative_destinations": [
    {
      "name": "Alternative destination name",
      "country": "Country",
      "reason": "Why it's a good alternative"
    }
  ],
  "travel_tips": [
    "Tip 1",
    "Tip 2",
    "Tip 3"
  ]
}"""
        
        # Call the API with low temperature for more structured responses
        response = self.generate_text(prompt, max_tokens=max_tokens, temperature=temperature)
        
        try:
            # Extract only the JSON part of the response (in case there's additional text)
            json_str = response[response.find('{'):response.rfind('}')+1]
            return json.loads(json_str)
        except json.JSONDecodeError:
            return {"error": "Could not generate a recommendation in valid JSON format", "raw_response": response}

# Example usage
if __name__ == "__main__":
    gemini = GeminiAPI()
    
    # Normal text generation example
    if input("Do you want to generate normal text? (y/n): ").lower() == 'y':
        prompt = input("Enter your prompt to generate text: ")
        generated_text = gemini.generate_text(prompt)
        
        print("\nGenerated text:")
        print("--------------")
        print(generated_text)
    
    # Travel recommendation example
    if input("\nDo you want to try the travel recommendation? (y/n): ").lower() == 'y':
        # Example questions and answers
        questions_answers = [
            {"question": "Do you want a relaxing vacation?", "answer": "yes"},
            {"question": "Are you interested in cultural experiences?", "answer": "yes"},
            {"question": "Do you prefer to travel internationally?", "answer": "yes"},
            {"question": "Do you want a short trip (less than 7 days)?", "answer": "no"},
            {"question": "Would you mind flying more than 5 hours?", "answer": "no"},
            {"question": "Would you be willing to stay in a hostel to save money?", "answer": "no"},
            {"question": "Are you looking for a family-friendly trip?", "answer": "no"},
            {"question": "Are you looking for a romantic getaway?", "answer": "yes"},
            {"question": "Are you interested in destinations with historical significance?", "answer": "yes"}
        ]
        
        print("\nGenerating travel recommendation...")
        recommendation = gemini.get_travel_recommendation(questions_answers)
        
        print("\nTravel recommendation:")
        print("----------------------")
        print(json.dumps(recommendation, indent=2))

