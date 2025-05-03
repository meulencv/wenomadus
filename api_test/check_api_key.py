import requests
import json
from config import API_KEY
from datetime import datetime, timedelta

def check_api_key():
    """Check if the API key is valid by making a simple request"""
    
    # Use the exact URL from the documentation
    url = "https://partners.api.skyscanner.net/apiservices/v3/flights/live/search/create"
    
    # Headers as specified in documentation
    headers = {
        "x-api-key": API_KEY,
        "Content-Type": "application/json"
    }
    
    # Get future date (7 days from now)
    future_date = datetime.now() + timedelta(days=7)
    
    # Simple minimal request body with future date
    data = {
        "query": {
            "market": "ES",
            "locale": "es-ES",
            "currency": "EUR",
            "queryLegs": [
                {
                    "originPlaceId": {"iata": "MAD"},
                    "destinationPlaceId": {"iata": "BCN"},
                    "date": {
                        "year": future_date.year,
                        "month": future_date.month,
                        "day": future_date.day
                    }
                }
            ],
            "adults": 1,
            "cabinClass": "CABIN_CLASS_ECONOMY"  # Adding valid cabin class
        }
    }
    
    print(f"Checking API key: {API_KEY[:5]}...{API_KEY[-4:]} (hidden middle)")
    print(f"Making request to: {url}")
    print(f"Using future date: {future_date.strftime('%Y-%m-%d')}")
    
    try:
        response = requests.post(url, headers=headers, json=data)
        status_code = response.status_code
        
        print(f"Response status code: {status_code}")
        
        if status_code == 200:
            print("✅ API key is valid!")
            print("Response preview:")
            response_json = response.json()
            print(json.dumps(response_json, indent=2)[:500] + "..." if len(json.dumps(response_json)) > 500 else "")
            return True
        elif status_code == 401 or status_code == 403:
            print("❌ Authentication failed - Invalid API key or insufficient permissions")
            print(f"Response: {response.text}")
        elif status_code == 404:
            print("❌ Endpoint not found - API structure may have changed")
        else:
            print(f"❌ Request failed with status code {status_code}")
            print(f"Response: {response.text}")
        
        return False
        
    except Exception as e:
        print(f"❌ Error occurred: {e}")
        return False

if __name__ == "__main__":
    print("\n===== SKYSCANNER API KEY CHECK =====\n")
    result = check_api_key()
    
    if not result:
        print("\n=== POSSIBLE ISSUES ===")
        print("1. Your API key might be invalid or expired")
        print("2. Your API key might not have the necessary permissions")
        print("3. The Skyscanner API might have changed - check documentation")
        print("4. You might need to apply for an API key with full access")
        print("\nFor more information, visit https://developers.skyscanner.net/docs")
