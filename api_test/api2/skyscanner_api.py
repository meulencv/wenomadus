import requests
import json
import time
from datetime import datetime, timedelta
import config  # Cambiamos el import relativo a absoluto

class SkyscannerApiClient:
    def __init__(self):
        self.api_key = config.API_KEY
        self.base_url = config.API_BASE_URL
        self.version = config.API_VERSION
        self.headers = {
            "x-api-key": self.api_key,
            "Content-Type": "application/json"
        }
    
    def _get_flights_url(self, endpoint):
        return f"{self.base_url}/{self.version}/flights/live/{endpoint}"
    
    def search_flights(self, origin, destination, date, adults=1, children_ages=None, 
                      market=config.DEFAULT_MARKET, locale=config.DEFAULT_LOCALE, 
                      currency=config.DEFAULT_CURRENCY, cabin_class="CABIN_CLASS_ECONOMY"):
        """
        Search for flights using the Skyscanner API
        """
        url = self._get_flights_url("search/create")
        
        # Format date as required by API
        travel_date = datetime.strptime(date, "%Y-%m-%d") if isinstance(date, str) else date
        
        query = {
            "query": {
                "market": market,
                "locale": locale,
                "currency": currency,
                "queryLegs": [
                    {
                        "originPlaceId": {"iata": origin},
                        "destinationPlaceId": {"iata": destination},
                        "date": {
                            "year": travel_date.year,
                            "month": travel_date.month,
                            "day": travel_date.day
                        }
                    }
                ],
                "adults": adults,
                "cabinClass": cabin_class
            }
        }
        
        if children_ages:
            query["query"]["childrenAges"] = children_ages
        
        response = requests.post(url, headers=self.headers, json=query)
        if response.status_code == 200:
            result = response.json()
            session_token = response.headers.get('x-session-token')
            return {
                "session_token": session_token,
                "results": result,
                "status": result.get("status")
            }
        else:
            return {"error": f"API request failed with status code {response.status_code}: {response.text}"}
    
    def poll_search_results(self, session_token):
        """
        Poll for complete search results
        """
        url = self._get_flights_url(f"search/poll/{session_token}")
        response = requests.post(url, headers=self.headers)
        
        if response.status_code == 200:
            return response.json()
        else:
            return {"error": f"Polling failed with status code {response.status_code}: {response.text}"}
    
    def complete_search(self, origin, destination, date, **kwargs):
        """
        Complete a flight search, polling until results are complete
        """
        # Realizar búsqueda inicial o usar un token existente
        existing_token = kwargs.pop('session_token', None)
        
        if existing_token:
            # Si se proporciona un token existente, úsalo
            session_token = existing_token
            # Realizar un primer poll para obtener el estado actual
            results = self.poll_search_results(session_token)
            if "error" in results:
                return results
            status = results.get("status")
        else:
            # Si no hay token, iniciar nueva búsqueda
            search_response = self.search_flights(origin, destination, date, **kwargs)
            
            if "error" in search_response:
                return search_response
            
            session_token = search_response["session_token"]
            status = search_response["results"].get("status")
            results = search_response["results"]
        
        # Poll for complete results if necessary
        poll_attempts = 0
        max_polls = 10  # Aumentando el número máximo de intentos
        
        while status == "RESULT_STATUS_INCOMPLETE" and poll_attempts < max_polls:
            poll_attempts += 1
            time.sleep(2)  # Wait before polling again
            poll_response = self.poll_search_results(session_token)
            
            if "error" not in poll_response:
                status = poll_response.get("status")
                results = poll_response
            else:
                return poll_response
        
        return results
    
    def get_destination_info(self, destination_iata):
        """
        Get information about a destination
        """
        # For a production application, you might need to use the culture API
        # or other endpoints to get detailed destination information
        # This is a placeholder for that functionality
        return {"iata": destination_iata, "name": f"Destination {destination_iata}"}
