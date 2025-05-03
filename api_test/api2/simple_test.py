from skyscanner_api import SkyscannerApiClient
from datetime import datetime, timedelta

def run_simple_test():
    # Crear cliente
    client = SkyscannerApiClient()
    
    # Parámetros de prueba
    origin = "MAD"  # Madrid
    destination = "BCN"  # Barcelona
    future_date = (datetime.now() + timedelta(days=30)).strftime("%Y-%m-%d")
    
    print(f"Probando búsqueda: {origin} → {destination} para {future_date}")
    
    # Buscar y hacer polling hasta completar
    results = client.complete_search(
        origin=origin,
        destination=destination,
        date=future_date,
        adults=1
    )
    
    # Mostrar resultados formateados
    formatted_results = client.format_itinerary_results(results)
    print(formatted_results)

if __name__ == "__main__":
    run_simple_test()
