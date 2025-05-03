def get_mock_flight_results():
    """Return mock flight search results for testing"""
    return {
        "status": "RESULT_STATUS_COMPLETE",
        "action": "RESULT_ACTION_COMPLETE",
        "sessionToken": "mock-session-token",
        "content": {
            "results": {
                "itineraries": {
                    "itinerary-1": {
                        "pricingOptions": [
                            {
                                "price": {
                                    "amount": 124.99,
                                    "unit": "EUR",
                                    "updateStatus": "PRICE_UPDATE_STATUS_COMPLETE"
                                },
                                "agentIds": ["agent-1"],
                                "transferType": "TRANSFER_TYPE_MANAGED",
                                "items": [
                                    {
                                        "price": {
                                            "amount": 124.99,
                                            "unit": "EUR"
                                        },
                                        "agentId": "agent-1",
                                        "deepLink": "https://example.com/booking"
                                    }
                                ]
                            }
                        ],
                        "legIds": ["leg-1"]
                    },
                    "itinerary-2": {
                        "pricingOptions": [
                            {
                                "price": {
                                    "amount": 156.50,
                                    "unit": "EUR",
                                    "updateStatus": "PRICE_UPDATE_STATUS_COMPLETE"
                                },
                                "agentIds": ["agent-2"],
                                "transferType": "TRANSFER_TYPE_MANAGED",
                                "items": [
                                    {
                                        "price": {
                                            "amount": 156.50,
                                            "unit": "EUR"
                                        },
                                        "agentId": "agent-2",
                                        "deepLink": "https://example.com/booking2"
                                    }
                                ]
                            }
                        ],
                        "legIds": ["leg-2"]
                    }
                },
                "legs": {
                    "leg-1": {
                        "originPlaceId": "MAD",
                        "destinationPlaceId": "BCN",
                        "departureDateTime": {
                            "year": 2023,
                            "month": 12,
                            "day": 25,
                            "hour": 8,
                            "minute": 30,
                            "second": 0
                        },
                        "arrivalDateTime": {
                            "year": 2023,
                            "month": 12,
                            "day": 25,
                            "hour": 10,
                            "minute": 0,
                            "second": 0
                        },
                        "durationInMinutes": 90,
                        "stopCount": 0,
                        "segmentIds": ["segment-1"],
                        "carriers": {
                            "marketing": ["IB"],
                            "operating": ["IB"]
                        },
                        "directionality": "OUTBOUND"
                    },
                    "leg-2": {
                        "originPlaceId": "MAD",
                        "destinationPlaceId": "BCN",
                        "departureDateTime": {
                            "year": 2023,
                            "month": 12,
                            "day": 25,
                            "hour": 14,
                            "minute": 15,
                            "second": 0
                        },
                        "arrivalDateTime": {
                            "year": 2023,
                            "month": 12,
                            "day": 25,
                            "hour": 15,
                            "minute": 45,
                            "second": 0
                        },
                        "durationInMinutes": 90,
                        "stopCount": 0,
                        "segmentIds": ["segment-2"],
                        "carriers": {
                            "marketing": ["VY"],
                            "operating": ["VY"]
                        },
                        "directionality": "OUTBOUND"
                    }
                },
                "segments": {
                    "segment-1": {
                        "originPlaceId": "MAD",
                        "destinationPlaceId": "BCN",
                        "departureDateTime": {
                            "year": 2023,
                            "month": 12,
                            "day": 25,
                            "hour": 8,
                            "minute": 30,
                            "second": 0
                        },
                        "arrivalDateTime": {
                            "year": 2023,
                            "month": 12,
                            "day": 25,
                            "hour": 10,
                            "minute": 0,
                            "second": 0
                        },
                        "durationInMinutes": 90,
                        "flightNumber": "IB6845",
                        "marketingFlightNumber": "IB6845",
                        "marketingCarrierId": "IB",
                        "operatingCarrierId": "IB"
                    },
                    "segment-2": {
                        "originPlaceId": "MAD",
                        "destinationPlaceId": "BCN",
                        "departureDateTime": {
                            "year": 2023,
                            "month": 12,
                            "day": 25,
                            "hour": 14,
                            "minute": 15,
                            "second": 0
                        },
                        "arrivalDateTime": {
                            "year": 2023,
                            "month": 12,
                            "day": 25,
                            "hour": 15,
                            "minute": 45,
                            "second": 0
                        },
                        "durationInMinutes": 90,
                        "flightNumber": "VY1004",
                        "marketingFlightNumber": "VY1004",
                        "marketingCarrierId": "VY",
                        "operatingCarrierId": "VY"
                    }
                },
                "places": {
                    "MAD": {
                        "name": "Madrid Barajas",
                        "type": "PLACE_TYPE_AIRPORT",
                        "iata": "MAD",
                        "coordinates": {
                            "latitude": 40.472,
                            "longitude": -3.5609
                        },
                        "parentId": "MADR"
                    },
                    "BCN": {
                        "name": "Barcelona El Prat",
                        "type": "PLACE_TYPE_AIRPORT",
                        "iata": "BCN",
                        "coordinates": {
                            "latitude": 41.2971,
                            "longitude": 2.0785
                        },
                        "parentId": "BARC"
                    }
                },
                "carriers": {
                    "IB": {
                        "name": "Iberia",
                        "allianceId": "ONEWORLD",
                        "displayCode": "IB"
                    },
                    "VY": {
                        "name": "Vueling",
                        "displayCode": "VY"
                    }
                },
                "agents": {
                    "agent-1": {
                        "name": "Iberia",
                        "type": "AGENT_TYPE_AIRLINE",
                        "imageUrl": "https://content.skyscanner.net/m/7b8c983a3caf9680/original/Iberia.png",
                        "optimisedForMobile": True
                    },
                    "agent-2": {
                        "name": "Vueling",
                        "type": "AGENT_TYPE_AIRLINE",
                        "imageUrl": "https://content.skyscanner.net/m/73f9ce508c87388c/original/Vueling.png",
                        "optimisedForMobile": True
                    }
                }
            },
            "stats": {
                "minPrice": {
                    "amount": 124.99,
                    "unit": "EUR"
                },
                "maxPrice": {
                    "amount": 156.50,
                    "unit": "EUR"
                },
                "itineraryCount": 2
            }
        }
    }
