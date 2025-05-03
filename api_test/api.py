from config import API_KEY
import requests
import json
from datetime import datetime, timedelta
import time

# Base URL for Skyscanner API
SKYSCANNER_API_BASE_URL = "https://partners.api.skyscanner.net/apiservices"

def get_future_date(days_ahead=7):
    """Get a future date in YYYY-MM-DD format"""
    future_date = datetime.now() + timedelta(days=days_ahead)
    return future_date.strftime("%Y-%m-%d")

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
    
    # Headers as specified in documentation
    headers = {
        "x-api-key": API_KEY,
        "Content-Type": "application/json"
    }
    
    print(f"\nMaking {method} request to: {url}")
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers)
        elif method == "POST":
            if data:
                print(f"Request data summary: {json.dumps(data, indent=2)[:200]}...")
            response = requests.post(url, headers=headers, json=data)
        else:
            raise ValueError(f"Unsupported HTTP method: {method}")
        
        print(f"Response status code: {response.status_code}")
        
        if response.status_code != 200:
            print(f"Error response: {response.text}")
        
        response.raise_for_status()  # Raise exception for bad status codes
        return response.json()
    
    except requests.exceptions.HTTPError as e:
        print(f"HTTP Error: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response content: {e.response.text}")
        raise e
    except Exception as e:
        print(f"Error: {e}")
        raise e

def get_culture_info():
    """
    Get culture information - NOT CURRENTLY WORKING
    This is kept for compatibility but will raise an exception
    """
    # NOTE: This endpoint doesn't seem to be accessible with the current API key
    raise NotImplementedError("Culture information endpoint is not available with the current API key")

def search_flights(origin, destination, date=None, return_date=None, adults=1):
    """
    Search for flights using the Live Prices API
    
    Args:
        origin (str): Origin place IATA code (e.g., 'LHR')
        destination (str): Destination place IATA code (e.g., 'JFK')
        date (str): Outbound date in YYYY-MM-DD format (defaults to 7 days from now)
        return_date (str, optional): Return date for round trips
        adults (int): Number of adult passengers
        
    Returns:
        dict: Flight search results and session token
    """
    # Use provided date or default to 7 days in future
    if date is None:
        date = get_future_date(7)
    
    # Parse the date components
    date_parts = date.split("-")
    year = int(date_parts[0])
    month = int(date_parts[1])
    day = int(date_parts[2])
        
    # Create query with proper format
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
                        "year": year,
                        "month": month,
                        "day": day
                    }
                }
            ],
            "adults": adults,
            "cabinClass": "CABIN_CLASS_ECONOMY",
            "includeSustainabilityData": True
        }
    }
    
    # Add return leg if return_date is provided
    if return_date:
        return_date_parts = return_date.split("-")
        return_year = int(return_date_parts[0])
        return_month = int(return_date_parts[1])
        return_day = int(return_date_parts[2])
        
        query["query"]["queryLegs"].append({
            "originPlaceId": {"iata": destination},
            "destinationPlaceId": {"iata": origin},
            "date": {
                "year": return_year,
                "month": return_month,
                "day": return_day
            }
        })
    
    # Make the request
    result = make_request("v3/flights/live/search/create", method="POST", data=query)
    
    # Extract the session token without the "-cells1" suffix which could be causing problems
    if "sessionToken" in result:
        original_token = result["sessionToken"]
        if original_token.endswith("-cells1"):
            # Store both tokens for reference
            result["originalSessionToken"] = original_token
            result["sessionToken"] = original_token.replace("-cells1", "")
    
    return result

def poll_flight_results(session_token):
    """
    Poll for flight search results using the session token
    
    Args:
        session_token (str): Session token from search_flights
        
    Returns:
        dict: Updated flight search results
    """
    # Try both with and without the -cells1 suffix
    original_token = session_token
    
    try:
        # First try with the original token
        return make_request(f"v3/flights/live/search/poll/{original_token}", method="POST")
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 404 and not session_token.endswith("-cells1"):
            # If 404 and no suffix, try adding the suffix
            print("Retrying with -cells1 suffix...")
            modified_token = f"{session_token}-cells1"
            return make_request(f"v3/flights/live/search/poll/{modified_token}", method="POST")
        else:
            # If that also fails, or if the error wasn't a 404, re-raise
            raise

def get_indicative_prices(origin, destination, date=None):
    """
    Get indicative (average) flight prices between two locations
    
    Args:
        origin (str): Origin place IATA code (e.g., 'LHR')
        destination (str): Destination place IATA code (e.g., 'JFK')
        date (str): Date in YYYY-MM-DD format (defaults to 30 days from now)
        
    Returns:
        dict: Indicative price data
    """
    # Use provided date or default to 30 days in future
    if date is None:
        date = get_future_date(30)
        
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
    
    # Updated endpoint for indicative prices
    return make_request("v3/flights/indicative/search", method="POST", data=query)

# Example usage when script is run directly
if __name__ == "__main__":
    try:
        print("Testing Skyscanner API with dynamic dates")
        future_date = get_future_date(7)
        print(f"Using future date: {future_date}")
        
        # Example flight search with future date
        search_results = search_flights("MAD", "BCN", date=future_date)
        print(f"Search status: {search_results.get('status')}")
        
        # If successful, get session token and poll for results
        session_token = search_results.get("sessionToken")
        if session_token:
            print(f"Session token: {session_token}")
            print("Polling for complete results...")
            poll_results = poll_flight_results(session_token)
            print(f"Updated status: {poll_results.get('status')}")
    
    except Exception as e:
        print(f"Error: {str(e)}")

