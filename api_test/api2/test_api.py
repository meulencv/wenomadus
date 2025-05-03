import sys
import json
import argparse
import time
from datetime import datetime, timedelta
from skyscanner_api import SkyscannerApiClient

def print_json(data):
    """Pretty print JSON data"""
    print(json.dumps(data, indent=2, ensure_ascii=False))

def test_search_flights(origin="MAD", destination="BCN", days_ahead=30, adults=2, children_ages=None, verbose=False):
    """Test the flight search functionality"""
    print(f"\n=== Probando búsqueda de vuelos {origin} → {destination} ===")
    
    # Crear cliente
    client = SkyscannerApiClient()
    
    # Fechas para el futuro 
    future_date = (datetime.now() + timedelta(days=days_ahead)).strftime("%Y-%m-%d")
    
    print(f"Buscando vuelos de {origin} a {destination} para la fecha {future_date}...")
    
    # Medir el tiempo de respuesta
    start_time = time.time()
    
    # Buscar vuelos
    search_result = client.search_flights(
        origin=origin,
        destination=destination,
        date=future_date,
        adults=adults,
        children_ages=children_ages
    )
    
    initial_response_time = time.time() - start_time
    print(f"Tiempo de respuesta inicial: {initial_response_time:.2f} segundos")
    
    # Comprobar si hay error
    if "error" in search_result:
        print(f"ERROR: {search_result['error']}")
        return
    
    # Mostrar token de sesión
    print(f"Token de sesión: {search_result['session_token']}")
    print(f"Estado inicial: {search_result['status']}")
    
    # Mostrar el primer resultado parcial (si se solicita modo detallado)
    print("\nResultados iniciales (parciales):")
    if "results" in search_result and "content" in search_result["results"]:
        if "results" in search_result["results"]["content"]:
            itineraries = search_result["results"]["content"]["results"].get("itineraries", {})
            if itineraries:
                print(f"Se encontraron {len(itineraries)} itinerarios iniciales")
                
                if verbose:
                    # Mostrar el primer itinerario como ejemplo
                    first_itinerary_id = list(itineraries.keys())[0]
                    first_itinerary = itineraries[first_itinerary_id]
                    print("\nPrimer itinerario encontrado:")
                    print_json(first_itinerary)
            else:
                print("No se encontraron itinerarios en los resultados iniciales")
    
    # Realizar una búsqueda completa usando el token de sesión que ya obtuvimos
    print("\n=== Realizando búsqueda completa (con polling) ===")
    
    start_time_complete = time.time()
    
    # Usar el token de sesión obtenido en la primera búsqueda
    if "error" not in search_result and "session_token" in search_result:
        complete_results = client.complete_search(
            origin=origin,
            destination=destination,
            date=future_date,
            adults=adults,
            children_ages=children_ages,
            session_token=search_result["session_token"]  # Reutilizar el token existente
        )
    else:
        complete_results = client.complete_search(
            origin=origin,
            destination=destination,
            date=future_date,
            adults=adults,
            children_ages=children_ages
        )
    
    complete_response_time = time.time() - start_time_complete
    print(f"Tiempo de respuesta completa: {complete_response_time:.2f} segundos")
    
    # Comprobar si hay error
    if "error" in complete_results:
        print(f"ERROR: {complete_results['error']}")
        return
    
    # Mostrar resultados completos
    print(f"\nEstado final: {complete_results.get('status', 'Unknown')}")
    
    if "content" in complete_results and "results" in complete_results["content"]:
        itineraries = complete_results["content"]["results"].get("itineraries", {})
        if itineraries:
            print(f"Se encontraron {len(itineraries)} itinerarios totales")
            
            # Mostrar estadísticas de precios
            if "stats" in complete_results["content"]["results"]:
                stats = complete_results["content"]["results"]["stats"]
                min_price = stats.get("minPrice", {})
                print(f"\nPrecio mínimo: {min_price.get('amount')} {min_price.get('unit', '')}")
            
            # Mostrar algunos detalles de vuelos encontrados
            print("\nAlgunas opciones de vuelo encontradas:")
            count = 0
            for itin_id, itin in itineraries.items():
                if count >= 3 and not verbose:  # Limitar a 3 ejemplos o mostrar todos en modo verbose
                    break
                
                pricing_options = itin.get("pricingOptions", [])
                if pricing_options:
                    price_info = pricing_options[0].get("price", {})
                    price = price_info.get("amount", "N/A")
                    currency = price_info.get("unit", "")
                    
                    # Get leg information
                    leg_ids = itin.get("legIds", [])
                    if leg_ids and "legs" in complete_results["content"]["results"]:
                        legs = complete_results["content"]["results"]["legs"]
                        if leg_ids[0] in legs:
                            leg = legs[leg_ids[0]]
                            origin_id = leg.get("originPlaceId")
                            dest_id = leg.get("destinationPlaceId")
                            duration = leg.get("durationInMinutes")
                            departure = leg.get("departureDateTime", {})
                            departure_time = f"{departure.get('hour', '00')}:{departure.get('minute', '00')}"
                            
                            # Mostrar información del vuelo
                            print(f"Vuelo {count+1}: {origin_id} → {dest_id}, {departure_time}, Precio: {price} {currency}, Duración: {duration} min.")
                            
                            # En modo verbose, mostrar más detalles
                            if verbose and count < 2:
                                segmentIds = leg.get("segmentIds", [])
                                if segmentIds and "segments" in complete_results["content"]["results"]:
                                    segments = complete_results["content"]["results"]["segments"]
                                    print("  Detalles del vuelo:")
                                    
                                    for seg_id in segmentIds:
                                        if seg_id in segments:
                                            segment = segments[seg_id]
                                            marketing_carrier = segment.get("marketingCarrierId", "")
                                            flight_number = segment.get("flightNumber", "")
                                            print(f"  - Operado por: {marketing_carrier} {flight_number}")
                            
                            count += 1
            
            if verbose:
                print("\nEjemplo de respuesta JSON completa (un itinerario):")
                first_itinerary_id = list(itineraries.keys())[0]
                print_json(itineraries[first_itinerary_id])
                
                print("\nEstructura completa de un 'leg':")
                first_leg_id = list(complete_results["content"]["results"]["legs"].keys())[0]
                print_json(complete_results["content"]["results"]["legs"][first_leg_id])
        else:
            print("No se encontraron itinerarios en los resultados completos")
    else:
        print("Formato de resultados inesperado o no hay resultados disponibles")
        
    return complete_results


def test_multiple_destinations():
    """Probar búsquedas para múltiples destinos populares desde un origen"""
    origen = "MAD"  # Madrid como origen
    destinos = ["BCN", "PAR", "LON", "ROM", "BER"]  # Barcelona, París, Londres, Roma, Berlín
    
    print("\n=== Prueba de múltiples destinos ===")
    print(f"Origen: {origen}")
    
    for destino in destinos:
        print(f"\n--- Probando ruta {origen} → {destino} ---")
        results = test_search_flights(origin=origen, destination=destino, verbose=False)
        
        # Añadir una pausa para no sobrecargar la API
        time.sleep(2)


def test_future_dates():
    """Probar búsquedas para diferentes fechas futuras"""
    origen = "MAD"
    destino = "BCN"
    periodos = [30, 60, 90]  # 1 mes, 2 meses, 3 meses
    
    print("\n=== Prueba de diferentes fechas futuras ===")
    print(f"Ruta: {origen} → {destino}")
    
    for dias in periodos:
        fecha = (datetime.now() + timedelta(days=dias)).strftime("%Y-%m-%d")
        print(f"\n--- Probando para fecha: {fecha} (en {dias} días) ---")
        results = test_search_flights(origin=origen, destination=destino, days_ahead=dias, verbose=False)
        
        # Añadir una pausa para no sobrecargar la API
        time.sleep(2)


if __name__ == "__main__":
    # Configurar el parser de argumentos
    parser = argparse.ArgumentParser(description='Test de la API de Skyscanner')
    parser.add_argument('--origen', '-o', default='MAD', help='Código IATA del aeropuerto de origen (default: MAD)')
    parser.add_argument('--destino', '-d', default='BCN', help='Código IATA del aeropuerto de destino (default: BCN)')
    parser.add_argument('--dias', '-t', type=int, default=30, help='Días en el futuro para la búsqueda (default: 30)')
    parser.add_argument('--adultos', '-a', type=int, default=2, help='Número de adultos (default: 2)')
    parser.add_argument('--ninos', '-n', type=str, help='Edades de niños separadas por comas, ej: "5,7,10"')
    parser.add_argument('--verbose', '-v', action='store_true', help='Mostrar información detallada')
    parser.add_argument('--multi', '-m', action='store_true', help='Probar múltiples destinos')
    parser.add_argument('--fechas', '-f', action='store_true', help='Probar diferentes fechas')
    
    args = parser.parse_args()
    
    print("=== Test de Integración con la API de Skyscanner ===")
    
    # Convertir las edades de los niños de string a lista si se proporcionan
    children_ages = None
    if args.ninos:
        try:
            children_ages = [int(age) for age in args.ninos.split(',')]
        except:
            print("Error: Formato incorrecto para las edades de niños. Use números separados por comas, ej: '5,7,10'")
            sys.exit(1)
    
    # Ejecutar los tests según los argumentos
    if args.multi:
        test_multiple_destinations()
    elif args.fechas:
        test_future_dates()
    else:
        test_search_flights(
            origin=args.origen,
            destination=args.destino,
            days_ahead=args.dias,
            adults=args.adultos,
            children_ages=children_ages,
            verbose=args.verbose
        )
