import json
import time
from api import (
    search_flights, 
    poll_flight_results, 
    get_future_date
)

def pretty_print(data):
    """Print JSON data in a readable format"""
    print(json.dumps(data, indent=2, ensure_ascii=False))

def example_culture_api():
    """Example of using Culture API to get markets, currencies and locales"""
    print("\n===== CULTURE API EXAMPLE =====")
    print("Sorry, the Culture API is not accessible with the current API key.")

def example_flight_search():
    """Example of using Flight Live Prices API for a one-way trip"""
    print("\n===== FLIGHT SEARCH EXAMPLE (ONE-WAY) =====")
    
    # Use dynamic future dates
    origin = "MAD"      # Madrid
    destination = "BCN"  # Barcelona
    future_date = get_future_date(10)  # 10 days in the future
    adults = 2
    
    print(f"Searching for flights from {origin} to {destination} on {future_date} for {adults} adults...")
    
    try:
        # Initial search with future date
        search_results = search_flights(origin, destination, date=future_date, adults=adults)
        session_token = search_results.get("sessionToken")
        
        print(f"Search status: {search_results.get('status')}")
        print(f"Session token: {session_token}")
        
        if search_results.get('status') == "RESULT_STATUS_INCOMPLETE" and session_token:
            print("Initial results are incomplete. Polling for more results...")
            print("Waiting 2 seconds before polling...")
            time.sleep(2)  # Add delay before polling
            
            # Poll for complete results
            try:
                poll_results = poll_flight_results(session_token)
                print(f"Updated status: {poll_results.get('status')}")
                
                # Process results here...
                if poll_results.get('content', {}).get('results', {}).get('itineraries'):
                    itineraries = poll_results['content']['results']['itineraries']
                    print(f"Found {len(itineraries)} itineraries")
                    
                    # Display results...
                    # ...existing code...
            except Exception as e:
                print(f"Error during polling: {e}")
                # Try to use the results from the initial search
                print("Using initial search results instead...")
                if search_results.get('content', {}).get('results', {}).get('itineraries'):
                    itineraries = search_results['content']['results']['itineraries']
                    print(f"Found {len(itineraries)} itineraries in initial results")
                    
                    # Display first itinerary
                    if itineraries:
                        first_itinerary = list(itineraries.values())[0]
                        price_options = first_itinerary.get('pricingOptions', [])
                        if price_options:
                            price_info = price_options[0]
                            price = price_info.get('price', {})
                            
                            print("\nExample itinerary:")
                            print(f"Price: {price.get('amount')} {price.get('currency')}")
                            print(f"Agent: {price_info.get('agentIds', [])[0] if price_info.get('agentIds') else 'Unknown'}")
    except Exception as e:
        print(f"Error in flight search: {str(e)}")

def find_cheapest_madrid_paris():
    """Simple function to find the cheapest flight from Madrid to Paris"""
    print("\n===== CHEAPEST FLIGHT: MADRID TO PARIS =====")
    
    # Set up the search parameters
    origin = "MAD"         # Madrid
    destination = "CDG"     # Paris Charles de Gaulle
    future_date = get_future_date(30)
    
    print(f"Searching for the cheapest flight from Madrid to Paris on {future_date}...")
    
    try:
        # Perform the search
        search_results = search_flights(origin, destination, date=future_date)
        
        # Extract itineraries
        content = search_results.get('content', {})
        results = content.get('results', {})
        itineraries = results.get('itineraries', {})
        
        if not itineraries:
            print("No flights found.")
            return
            
        # Get reference data
        places = content.get('places', {})
        carriers = content.get('carriers', {})
        legs = results.get('legs', {})
        
        # Find the cheapest itinerary
        cheapest_price = float('inf')
        cheapest_itinerary = None
        cheapest_currency = "EUR"  # Default currency
        
        for itin_id, itinerary in itineraries.items():
            if not itinerary.get('pricingOptions'):
                continue
                
            # Get price information
            price_info = itinerary['pricingOptions'][0].get('price', {})
            price_str = price_info.get('amount')
            currency = price_info.get('currency', 'EUR')  # Get currency with default
            
            # Convert price to float for comparison
            try:
                price = float(price_str) if price_str is not None else None
                if price is not None and price < cheapest_price:
                    cheapest_price = price
                    cheapest_itinerary = itinerary
                    cheapest_currency = currency
            except (ValueError, TypeError):
                # Skip itineraries with invalid price values
                continue
        
        if not cheapest_itinerary:
            print("No valid price information found for any flights.")
            return
            
        # Display the cheapest flight details - use the saved currency instead of accessing it from the itinerary
        leg_id = cheapest_itinerary.get('legIds', [None])[0]  # Get the first leg safely
        if not leg_id:
            print(f"Price: {cheapest_price} {cheapest_currency}")
            print("Incomplete flight information")
            return
            
        leg = legs.get(leg_id, {})
        
        # Get airline information
        segment_ids = leg.get('segmentIds', [])
        airline = "Unknown"
        if segment_ids:
            segment = results.get('segments', {}).get(segment_ids[0], {})
            carrier_id = segment.get('marketingCarrierId')
            airline = carriers.get(carrier_id, {}).get('name', "Unknown")
        
        # Format the departure and arrival times
        dep_time = leg.get('departureDateTime', {})
        arr_time = leg.get('arrivalDateTime', {})
        
        # More safely format time strings
        try:
            dep_str = f"{dep_time.get('hour', 0):02d}:{dep_time.get('minute', 0):02d}, {dep_time.get('day', 0)}/{dep_time.get('month', 0)}" if dep_time else "Unknown"
        except (TypeError, ValueError):
            dep_str = "Unknown"
            
        try:
            arr_str = f"{arr_time.get('hour', 0):02d}:{arr_time.get('minute', 0):02d}, {arr_time.get('day', 0)}/{arr_time.get('month', 0)}" if arr_time else "Unknown"
        except (TypeError, ValueError):
            arr_str = "Unknown"
        
        # Get duration
        duration_mins = leg.get('durationInMinutes', 0)
        hours = duration_mins // 60
        mins = duration_mins % 60
        
        # Display the result in a simple format
        print("\n💰 CHEAPEST FLIGHT FOUND 💰")
        print(f"Price: {cheapest_price} {cheapest_currency}")
        print(f"Airline: {airline}")
        print(f"Departure: {dep_str}")
        print(f"Arrival: {arr_str}")
        print(f"Duration: {hours}h {mins}m")
        print(f"Stops: {len(segment_ids) - 1}")
        
        # Show booking agent
        price_options = cheapest_itinerary.get('pricingOptions', [])
        if price_options:
            agent_ids = price_options[0].get('agentIds', [])
            if agent_ids:
                agent = content.get('agents', {}).get(agent_ids[0], {}).get('name', agent_ids[0])
                print(f"Book with: {agent}")
                
                # Show deep link if available
                items = price_options[0].get('items', [])
                if items and items[0].get('deepLink'):
                    print(f"Booking link available: Yes")
        
    except Exception as e:
        import traceback
        print(f"Error finding cheapest flight: {e}")
        print("Stack trace:")
        traceback.print_exc()

if __name__ == "__main__":
    # Run only the simplified Madrid to Paris search
    try:
        find_cheapest_madrid_paris()
    except Exception as e:
        print(f"Error: {e}")
