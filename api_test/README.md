# Skyscanner API Integration

Este proyecto contiene ejemplos de cómo interactuar con la API de Skyscanner para búsqueda de vuelos y precios indicativos.

## Configuración

1. Crea un archivo `config.py` con tu clave de API:

```python
API_KEY = "tu_clave_de_api_aquí"
```

2. Instala las dependencias:

```bash
pip install requests
```

## Ejemplos disponibles

Este proyecto incluye varios ejemplos de uso de la API de Skyscanner:

- **Culture API**: Obtener información sobre mercados, divisas e idiomas
- **Flight Live Prices API**: Búsqueda de vuelos en tiempo real (ida y vuelta)
- **Flight Indicative Prices API**: Obtener precios indicativos entre destinos

## Uso básico

```python
from api import search_flights, poll_flight_results

# Buscar vuelos de Madrid a Barcelona
results = search_flights(
    origin="MAD", 
    destination="BCN", 
    date="2023-12-01"
)

# Si los resultados están incompletos, usar el token para actualizar
if results.get('status') == "RESULT_STATUS_INCOMPLETE":
    session_token = results.get('sessionToken')
    updated_results = poll_flight_results(session_token)
```

## Ejecutar ejemplos

```bash
# Ejecutar ejemplos básicos incluidos en api.py
python api.py

# Ejecutar ejemplos más detallados
python examples.py
```

## Documentación de la API

Para más información, consulta la documentación oficial:
https://developers.skyscanner.net/docs
