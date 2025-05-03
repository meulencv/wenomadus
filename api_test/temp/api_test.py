API_KEY = "sh967490139224896692439644109194"

import requests
import json
import time
from datetime import datetime, timedelta

# API endpoints
CREATE_URL = "https://partners.api.skyscanner.net/apiservices/v3/flights/live/search/create"
POLL_URL_BASE = "https://partners.api.skyscanner.net/apiservices/v3/flights/live/search/poll"

def create_search(origin, destination, date):
    """Create a flight search"""
    headers = {
        "x-api-key": API_KEY,
        "Content-Type": "application/json"
    }
    
    # Parse date components
    date_obj = datetime.strptime(date, '%Y-%m-%d')
    
    # Prepare request body
    data = {
        "query": {
            "market": "ES",
            "locale": "es-ES",
            "currency": "EUR",
            "queryLegs": [
                {
                    "originPlaceId": {"iata": origin},
                    "destinationPlaceId": {"iata": destination},
                    "date": {
                        "year": date_obj.year,
                        "month": date_obj.month,
                        "day": date_obj.day
                    }
                }
            ],
            "adults": 1,
            "cabinClass": "CABIN_CLASS_ECONOMY"
        }
    }
    
    try:
        response = requests.post(CREATE_URL, headers=headers, json=data)
        response.raise_for_status()  # Raise exception for 4XX/5XX responses
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error creating search: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response: {e.response.text}")
        return None

def poll_results(session_token):
    """Poll for search results"""
    headers = {
        "x-api-key": API_KEY
    }
    
    url = f"{POLL_URL_BASE}/{session_token}"
    
    try:
        response = requests.post(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error polling results: {e}")
        if hasattr(e, 'response') and e.response:
            print(f"Response: {e.response.text}")
        return None

def display_results(results):
    """Display flight search results in a readable format"""
    if not results:
        print("No results to display.")
        return
    
    # Check if the search is complete or still in progress
    status = results.get("status", "UNKNOWN")
    print(f"Search status: {status}")
    
    # Display basic info about itineraries
    itineraries = results.get("content", {}).get("results", {}).get("itineraries", {})
    if not itineraries:
        print("No itineraries found.")
        return
    
    print(f"\nFound {len(itineraries)} itineraries:")
    for itinerary_id, itinerary in itineraries.items():
        print("-" * 50)
        print(f"Itinerary ID: {itinerary_id}")
        
        # Get pricing options
        pricing = itinerary.get("pricingOptions", [])
        if pricing:
            cheapest = min(pricing, key=lambda x: x.get("price", {}).get("amount", float('inf')))
            price = cheapest.get("price", {})
            # Convert from string to float before dividing
            try:
                amount = float(price.get('amount', 0)) / 100
                print(f"Price: {amount:.2f} {price.get('currency', 'EUR')}")
            except (ValueError, TypeError):
                # Handle case where amount is not a valid number
                print(f"Price: {price.get('amount')} {price.get('currency', 'EUR')}")
            
            # Get agent info
            agent_ids = cheapest.get("agentIds", [])
            if agent_ids:
                print(f"Agents: {', '.join(agent_ids)}")
        
        # Get leg info
        leg_ids = itinerary.get("legIds", [])
        legs = results.get("content", {}).get("results", {}).get("legs", {})
        
        for leg_id in leg_ids:
            leg = legs.get(leg_id, {})
            origin = leg.get("originPlaceId", "")
            destination = leg.get("destinationPlaceId", "")
            departure = leg.get("departureDateTime", {})
            arrival = leg.get("arrivalDateTime", {})
            
            dep_time = f"{departure.get('year', '')}-{departure.get('month', '')}-{departure.get('day', '')} {departure.get('hour', '')}:{departure.get('minute', ''):02d}"
            arr_time = f"{arrival.get('year', '')}-{arrival.get('month', '')}-{arrival.get('day', '')} {arrival.get('hour', '')}:{arrival.get('minute', ''):02d}"
            
            print(f"Route: {origin} → {destination}")
            print(f"Departure: {dep_time}")
            print(f"Arrival: {arr_time}")
            
            # Show segments/stops
            segments = leg.get("segmentIds", [])
            if len(segments) > 1:
                print(f"Stops: {len(segments) - 1}")

def run_test():
    """Run a simple test of the Skyscanner API"""
    print("Testing Skyscanner API...")
    
    # Set origin, destination and date for test (one month from today)
    origin = "MAD"  # Madrid
    destination = "BCN"  # Barcelona
    future_date = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d')
    
    print(f"Searching for flights: {origin} → {destination} on {future_date}")
    
    # Create search
    create_response = create_search(origin, destination, future_date)
    
    if not create_response:
        print("Failed to create search. Exiting.")
        return
    
    # Get session token
    session_token = create_response.get("sessionToken")
    if not session_token:
        print("No session token in response. Exiting.")
        return
    
    print(f"Search created. Session token: {session_token}")
    
    # Display initial results
    display_results(create_response)
    
    # Poll for final results (up to 3 times)
    print("\nPolling for complete results...")
    max_polls = 3
    for i in range(max_polls):
        print(f"Poll attempt {i+1}/{max_polls}")
        time.sleep(2)  # Wait before polling
        
        poll_response = poll_results(session_token)
        if not poll_response:
            print("Failed to poll results.")
            continue
        
        display_results(poll_response)
        
        # Check if search is complete
        status = poll_response.get("status")
        if status == "RESULT_STATUS_COMPLETE":
            print("Search completed successfully.")
            break

if __name__ == "__main__":
    run_test()