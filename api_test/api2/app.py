from flask import Flask, request, jsonify
from skyscanner_api import SkyscannerApiClient  # Cambiamos el import relativo a absoluto
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create an instance of the Skyscanner API client
skyscanner_client = SkyscannerApiClient()

@app.route('/api/search', methods=['POST'])
def search_flights():
    """
    Search for flights using the Skyscanner API
    Expected JSON payload:
    {
        "origin": "MAD",
        "destination": "BCN",
        "date": "2023-12-25",
        "adults": 2,
        "children_ages": [5, 7]  // optional
    }
    """
    try:
        data = request.json
        logger.info(f"Received search request: {data}")
        
        # Extract required parameters
        origin = data.get('origin')
        destination = data.get('destination')
        date = data.get('date')
        adults = data.get('adults', 1)
        children_ages = data.get('children_ages')
        
        # Validate required parameters
        if not all([origin, destination, date]):
            return jsonify({"error": "Missing required parameters"}), 400
        
        # Call the API client
        result = skyscanner_client.complete_search(
            origin=origin,
            destination=destination,
            date=date,
            adults=adults,
            children_ages=children_ages
        )
        
        return jsonify(result)
    
    except Exception as e:
        logger.error(f"Error in search_flights: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route('/api/destination/<iata_code>', methods=['GET'])
def get_destination(iata_code):
    """
    Get information about a destination by IATA code
    """
    try:
        result = skyscanner_client.get_destination_info(iata_code)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error in get_destination: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
