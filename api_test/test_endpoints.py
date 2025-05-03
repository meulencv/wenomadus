import requests
import json
from config import API_KEY

def test_endpoint(endpoint, method="GET", data=None):
    """Simple function to test an API endpoint"""
    
    base_url = "https://partners.api.skyscanner.net/apiservices"
    url = f"{base_url}/{endpoint}"
    
    headers = {
        "x-api-key": API_KEY,
        "Content-Type": "application/json"
    }
    
    print(f"Testing {method} request to: {url}")
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers)
        else:
            response = requests.post(url, headers=headers, json=data)
        
        print(f"Status code: {response.status_code}")
        
        if response.status_code == 200:
            print("Response (sample):")
            response_json = response.json()
            print(json.dumps(response_json, indent=2)[:500] + "..." if len(json.dumps(response_json)) > 500 else "")
            return True
        else:
            print(f"Error response: {response.text}")
            return False
    
    except Exception as e:
        print(f"Exception: {str(e)}")
        return False

if __name__ == "__main__":
    print("\n=== Testing Skyscanner API Endpoints ===\n")
    
    # Test all culture endpoints
    endpoints = [
        "v3/culture/markets-currencies-languages",
        "v3/geo/hierarchy/flights",
        "v3/flights/live/search/create"
    ]
    
    for endpoint in endpoints:
        print(f"\nTesting: {endpoint}")
        
        # Only POST for flights search
        if endpoint == "v3/flights/live/search/create":
            # Sample flight search query
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
                                "year": 2023,
                                "month": 12,
                                "day": 10
                            }
                        }
                    ],
                    "adults": 1,
                    "childrenAges": []
                }
            }
            success = test_endpoint(endpoint, method="POST", data=data)
        else:
            success = test_endpoint(endpoint)
            
        print(f"Success: {success}")
    
    print("\nEndpoint testing completed.")
