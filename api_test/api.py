from config import API_KEY
import requests
import json

# Base URL for Skyscanner API v3
SKYSCANNER_API_BASE_URL = "https://partners.api.skyscanner.net/apiservices/v3"

# Headers for authentication
headers = {
    "x-api-key": API_KEY,
    "Content-Type": "application/json"
}

def make_request(endpoint, method="GET", data=None):
    """
    Make a request to the Skyscanner API
    
    Args:
        endpoint (str): API endpoint
        method (str): HTTP method (GET, POST)
        data (dict): Request body for POST requests
        
    Returns:
        dict: API response as JSON
    """
    url = f"{SKYSCANNER_API_BASE_URL}/{endpoint}"
    
    if method == "GET":
        response = requests.get(url, headers=headers)
    elif method == "POST":
        response = requests.post(url, headers=headers, json=data)
    else:
        raise ValueError(f"Unsupported HTTP method: {method}")
    
    response.raise_for_status()  # Raise exception for bad status codes
    return response.json()

def get_culture_info():
    """Get culture information including markets, currencies, and locales"""
    return make_request("culture/markets-currencies-languages")

def search_flights(origin, destination, date, return_date=None, adults=1):
    """
    Search for flights using the Live Prices API
    
    Args:
        origin (str): Origin place IATA code (e.g., 'LHR')
        destination (str): Destination place IATA code (e.g., 'JFK')
        date (str): Outbound date in YYYY-MM-DD format
        return_date (str, optional): Return date for round trips
        adults (int): Number of adult passengers
        
    Returns:
        dict: Flight search results and session token
    """
    query = {
        "query": {
            "market": "ES",
            "locale": "es-ES",
            "currency": "EUR",
            "queryLegs": [
                {
                    "originPlaceId": {"iata": origin},
                    "destinationPlaceId": {"iata": destination},
                    "date": {
                        "year": int(date.split("-")[0]),
                        "month": int(date.split("-")[1]),
                        "day": int(date.split("-")[2])
                    }
                }
            ],
            "adults": adults,
            "childrenAges": []
        }
    }
    
    # Add return leg if return_date is provided
    if return_date:
        query["query"]["queryLegs"].append({
            "originPlaceId": {"iata": destination},
            "destinationPlaceId": {"iata": origin},
            "date": {
                "year": int(return_date.split("-")[0]),
                "month": int(return_date.split("-")[1]),
                "day": int(return_date.split("-")[2])
            }
        })
    
    return make_request("flights/live/search/create", method="POST", data=query)

def poll_flight_results(session_token):
    """
    Poll for flight search results using the session token
    
    Args:
        session_token (str): Session token from search_flights
        
    Returns:
        dict: Updated flight search results
    """
    return make_request(f"flights/live/search/poll/{session_token}")

def get_indicative_prices(origin, destination, date):
    """
    Get indicative (average) flight prices between two locations
    
    Args:
        origin (str): Origin place IATA code (e.g., 'LHR')
        destination (str): Destination place IATA code (e.g., 'JFK')
        date (str): Date in YYYY-MM-DD format
        
    Returns:
        dict: Indicative price data
    """
    query = {
        "query": {
            "market": "ES",
            "locale": "es-ES",
            "currency": "EUR",
            "dateTimeGroupingType": "DATE",
            "originPlace": {
                "queryPlace": {
                    "iata": origin
                }
            },
            "destinationPlace": {
                "queryPlace": {
                    "iata": destination
                }
            },
            "outboundDate": date,
        }
    }
    
    return make_request("flights/indicative/search", method="POST", data=query)

# Usage examples
if __name__ == "__main__":
    # Example 1: Get culture information
    print("\n=== Culture Information ===")
    culture_info = get_culture_info()
    print(f"Available markets: {len(culture_info['markets'])}")
    print(f"Available currencies: {len(culture_info['currencies'])}")
    print(f"First market: {culture_info['markets'][0]}")
    
    # Example 2: Search for flights
    print("\n=== Flight Search Example ===")
    print("Searching for flights from Madrid (MAD) to Barcelona (BCN)...")
    search_results = search_flights("MAD", "BCN", "2023-12-01")
    session_token = search_results.get("sessionToken")
    
    print(f"Search status: {search_results.get('status')}")
    print(f"Session token: {session_token}")
    
    if search_results.get('status') == "RESULT_STATUS_INCOMPLETE" and session_token:
        print("Polling for complete results...")
        poll_results = poll_flight_results(session_token)
        print(f"Updated status: {poll_results.get('status')}")
    
    # Example 3: Get indicative prices
    print("\n=== Indicative Prices Example ===")
    indicative_prices = get_indicative_prices("MAD", "BCN", "2023-12-01")
    print(f"Status: {indicative_prices.get('status')}")
    if indicative_prices.get('quotes'):
        print(f"Number of quotes: {len(indicative_prices['quotes'])}")
        if indicative_prices['quotes']:
            first_quote = indicative_prices['quotes'][0]
            print(f"First quote price: {first_quote.get('minPrice', {}).get('amount')} {first_quote.get('minPrice', {}).get('currency')}")

