import requests
import json
import time
from datetime import datetime, timedelta
import config
import logging

# Configuración básica de logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

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
        
        logger.info(f"Buscando vuelos: {origin} → {destination}, fecha: {date}")
        
        try:
            response = requests.post(url, headers=self.headers, json=query)
            
            if response.status_code == 200:
                result = response.json()
                # El token de sesión viene como header y también en el JSON de respuesta
                session_token = response.headers.get('x-session-token') or result.get("sessionToken")
                
                logger.info(f"Búsqueda exitosa, token: {session_token}")
                
                return {
                    "session_token": session_token,
                    "results": result,
                    "status": result.get("status")
                }
            else:
                logger.error(f"Error en la búsqueda: {response.status_code}, {response.text}")
                return {"error": f"API request failed with status code {response.status_code}: {response.text}"}
                
        except Exception as e:
            logger.exception("Error durante la petición de búsqueda")
            return {"error": f"Request exception: {str(e)}"}
    
    def poll_search_results(self, session_token):
        """
        Poll for complete search results
        """
        # No modificar el token - usar exactamente como viene de la API
        url = self._get_flights_url(f"search/poll/{session_token}")
        logger.info(f"Polling con token: {session_token}")
        
        try:
            # Solo usar los headers básicos, sin añadir el token como header
            response = requests.post(url, headers=self.headers)
            
            if response.status_code == 200:
                logger.info(f"Polling exitoso con status code: {response.status_code}")
                return response.json()
            else:
                logger.error(f"Error en polling: {response.status_code}, {response.text}")
                return {"error": f"Polling failed with status code {response.status_code}: {response.text}"}
                
        except Exception as e:
            logger.exception("Error durante el polling")
            return {"error": f"Polling exception: {str(e)}"}
    
    def complete_search(self, origin, destination, date, **kwargs):
        """
        Complete a flight search, polling until results are complete
        """
        # Realizar búsqueda inicial
        search_response = self.search_flights(origin, destination, date, **kwargs)
        
        if "error" in search_response:
            logger.error(f"Error en búsqueda inicial: {search_response['error']}")
            return search_response
        
        session_token = search_response["session_token"]
        results = search_response["results"]
        
        # Verificar si necesitamos hacer polling
        status = results.get("status")
        
        if status != "RESULT_STATUS_COMPLETE":
            # Esperar un poco antes de empezar polling
            time.sleep(2)
            
            # Poll for complete results
            poll_attempts = 0
            max_polls = 3  # Reducir a 3 intentos como en tu script de ejemplo
            
            while status == "RESULT_STATUS_INCOMPLETE" and poll_attempts < max_polls:
                poll_attempts += 1
                logger.info(f"Intento de polling #{poll_attempts}")
                
                poll_response = self.poll_search_results(session_token)
                
                if "error" not in poll_response:
                    status = poll_response.get("status")
                    results = poll_response
                    logger.info(f"Polling exitoso, estado: {status}")
                    
                    # Si la búsqueda está completa, terminar
                    if status == "RESULT_STATUS_COMPLETE":
                        break
                else:
                    logger.error(f"Error en polling: {poll_response['error']}")
                    return poll_response
                
                # Esperar entre intentos como en tu script (2 segundos)
                time.sleep(2)
        
        return results
    
    def get_destination_info(self, destination_iata):
        """
        Get information about a destination
        """
        # Esta es una implementación simulada
        # En una aplicación real, usarías la Culture API u otros endpoints
        return {"iata": destination_iata, "name": f"Destination {destination_iata}"}

    def format_itinerary_results(self, results):
        """
        Format itinerary results in a human-readable format
        """
        if not results or "error" in results:
            return "No hay resultados para mostrar"
            
        output = []
        
        # Estado de la búsqueda
        status = results.get("status", "UNKNOWN")
        output.append(f"Estado de la búsqueda: {status}")
        
        # Itinerarios
        itineraries = results.get("content", {}).get("results", {}).get("itineraries", {})
        if not itineraries:
            output.append("No se encontraron itinerarios.")
            return "\n".join(output)
        
        output.append(f"\nSe encontraron {len(itineraries)} itinerarios:")
        
        # Ordenar por precio (menor a mayor)
        sorted_itineraries = []
        for itin_id, itin in itineraries.items():
            pricing = itin.get("pricingOptions", [])
            if pricing:
                price = min([p.get("price", {}).get("amount", float('inf')) for p in pricing])
                sorted_itineraries.append((itin_id, itin, price))
        
        sorted_itineraries.sort(key=lambda x: x[2])
        
        # Mostrar los primeros 5 itinerarios (los más baratos)
        for itin_id, itin, _ in sorted_itineraries[:5]:
            output.append("-" * 40)
            
            # Precio
            pricing = itin.get("pricingOptions", [])
            if pricing:
                cheapest = min(pricing, key=lambda x: x.get("price", {}).get("amount", float('inf')))
                price = cheapest.get("price", {})
                price_amount = price.get("amount", "N/A")
                price_currency = price.get("unit", "EUR")
                output.append(f"Precio: {price_amount} {price_currency}")
                
                # Agentes
                agents = cheapest.get("agentIds", [])
                if agents:
                    output.append(f"Agencias: {', '.join(agents)}")
            
            # Info del vuelo
            leg_ids = itin.get("legIds", [])
            legs = results.get("content", {}).get("results", {}).get("legs", {})
            
            for leg_id in leg_ids:
                if leg_id in legs:
                    leg = legs[leg_id]
                    origin = leg.get("originPlaceId", "")
                    destination = leg.get("destinationPlaceId", "")
                    
                    # Fechas de salida y llegada
                    dep = leg.get("departureDateTime", {})
                    arr = leg.get("arrivalDateTime", {})
                    
                    dep_str = f"{dep.get('year')}-{dep.get('month')}-{dep.get('day')} {dep.get('hour')}:{dep.get('minute'):02d}"
                    arr_str = f"{arr.get('year')}-{arr.get('month')}-{arr.get('day')} {arr.get('hour')}:{arr.get('minute'):02d}"
                    
                    output.append(f"Ruta: {origin} → {destination}")
                    output.append(f"Salida: {dep_str}")
                    output.append(f"Llegada: {arr_str}")
                    
                    # Duración y escalas
                    duration = leg.get("durationInMinutes")
                    if duration:
                        hours, minutes = divmod(duration, 60)
                        output.append(f"Duración: {hours}h {minutes}min")
                    
                    stop_count = leg.get("stopCount", 0)
                    if stop_count > 0:
                        output.append(f"Escalas: {stop_count}")
        
        return "\n".join(output)
