import json
from api import (
    get_culture_info, 
    search_flights, 
    poll_flight_results, 
    get_indicative_prices
)

def pretty_print(data):
    """Print JSON data in a readable format"""
    print(json.dumps(data, indent=2, ensure_ascii=False))

def example_culture_api():
    """Example of using Culture API to get markets, currencies and locales"""
    print("\n===== CULTURE API EXAMPLE =====")
    culture_data = get_culture_info()
    
    print("\n== Available Markets (first 5) ==")
    for market in culture_data["markets"][:5]:
        print(f"Code: {market['code']}, Name: {market['name']}")
    
    print("\n== Available Currencies (first 5) ==")
    for currency in culture_data["currencies"][:5]:
        print(f"Code: {currency['code']}, Symbol: {currency['symbol']}")
    
    print("\n== Available Locales (first 5) ==")
    for locale in culture_data["locales"][:5]:
        print(f"Code: {locale['code']}, Name: {locale['name']}")

def example_flight_search():
    """Example of using Flight Live Prices API for a one-way trip"""
    print("\n===== FLIGHT SEARCH EXAMPLE (ONE-WAY) =====")
    
    origin = "MAD"      # Madrid
    destination = "BCN"  # Barcelona
    date = "2023-12-10"
    adults = 2
    
    print(f"Searching for flights from {origin} to {destination} on {date} for {adults} adults...")
    
    # Initial search
    search_results = search_flights(origin, destination, date, adults=adults)
    session_token = search_results.get("sessionToken")
    
    print(f"Search status: {search_results.get('status')}")
    
    if search_results.get('status') == "RESULT_STATUS_INCOMPLETE" and session_token:
        print("Initial results are incomplete. Polling for more results...")
        
        # Poll for complete results (you might need to poll multiple times)
        poll_results = poll_flight_results(session_token)
        print(f"Updated status: {poll_results.get('status')}")
        
        # Check if we have itineraries
        if poll_results.get('content', {}).get('results', {}).get('itineraries'):
            itineraries = poll_results['content']['results']['itineraries']
            print(f"Found {len(itineraries)} itineraries")
            
            # Show first itinerary details
            if itineraries:
                first_itinerary = list(itineraries.values())[0]
                price_info = first_itinerary.get('pricingOptions', [])[0]
                price = price_info.get('price', {})
                
                print("\nExample itinerary:")
                print(f"Price: {price.get('amount')} {price.get('currency')}")
                print(f"Agent: {price_info.get('agentIds', [])[0]}")

def example_round_trip_search():
    """Example of using Flight Live Prices API for a round trip"""
    print("\n===== FLIGHT SEARCH EXAMPLE (ROUND TRIP) =====")
    
    origin = "MAD"      # Madrid
    destination = "LHR"  # London Heathrow
    outbound_date = "2023-12-10"
    return_date = "2023-12-17"
    
    print(f"Searching for flights from {origin} to {destination}")
    print(f"Outbound: {outbound_date}, Return: {return_date}")
    
    # Perform search
    search_results = search_flights(origin, destination, outbound_date, return_date=return_date)
    session_token = search_results.get("sessionToken")
    
    print(f"Search status: {search_results.get('status')}")
    
    if session_token:
        # Poll for complete results
        poll_results = poll_flight_results(session_token)
        print(f"Updated status: {poll_results.get('status')}")
        
        # Display number of legs found
        if poll_results.get('content', {}).get('results', {}).get('legs'):
            legs = poll_results['content']['results']['legs']
            print(f"Found {len(legs)} flight legs")

def example_indicative_prices():
    """Example of using Flight Indicative Prices API"""
    print("\n===== INDICATIVE PRICES EXAMPLE =====")
    
    origin = "BCN"      # Barcelona
    destination = "NYC"  # New York
    date = "2023-12-15"
    
    print(f"Getting indicative prices from {origin} to {destination} on {date}...")
    
    price_data = get_indicative_prices(origin, destination, date)
    print(f"Status: {price_data.get('status')}")
    
    quotes = price_data.get('quotes', [])
    if quotes:
        print(f"Found {len(quotes)} quotes")
        
        # Show some example quotes
        for i, quote in enumerate(quotes[:3]):  # Show first 3 quotes
            min_price = quote.get('minPrice', {})
            print(f"\nQuote {i+1}:")
            print(f"Price: {min_price.get('amount')} {min_price.get('currency')}")
            print(f"Direct: {'Yes' if quote.get('isDirect') else 'No'}")
            print(f"Date: {quote.get('outboundDate')}")

if __name__ == "__main__":
    # Run examples
    try:
        example_culture_api()
        example_flight_search()
        example_round_trip_search()
        example_indicative_prices()
    except Exception as e:
        print(f"Error: {e}")
