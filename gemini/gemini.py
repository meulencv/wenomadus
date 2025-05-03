from api import API_KEY
import requests
import json

class GeminiAPI:
    """Clase para interactuar con la API de Gemini"""
    
    def __init__(self):
        self.api_key = API_KEY
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models"
        self.model = "gemini-2.0-flash"
    
    def generar_texto(self, prompt, max_tokens=1024, temperature=0.7):
        """
        Genera texto a partir de un prompt utilizando la API de Gemini
        
        Args:
            prompt (str): El texto de entrada para generar contenido
            max_tokens (int): Número máximo de tokens a generar
            temperature (float): Controla la aleatoriedad (0.0-1.0)
            
        Returns:
            str: Texto generado
        """
        url = f"{self.base_url}/{self.model}:generateContent?key={self.api_key}"
        
        payload = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }],
            "generationConfig": {
                "maxOutputTokens": max_tokens,
                "temperature": temperature
            }
        }
        
        headers = {"Content-Type": "application/json"}
        
        try:
            response = requests.post(url, headers=headers, data=json.dumps(payload))
            response.raise_for_status()  # Levantar excepción si hay error HTTP
            
            resultado = response.json()
            if 'candidates' in resultado and resultado['candidates']:
                return resultado['candidates'][0]['content']['parts'][0]['text']
            else:
                return "No se pudo generar texto. Respuesta: " + str(resultado)
                
        except Exception as e:
            return f"Error al llamar a la API: {str(e)}"

# Ejemplo de uso
if __name__ == "__main__":
    gemini = GeminiAPI()
    
    prompt = input("Escribe tu prompt para generar texto: ")
    texto_generado = gemini.generar_texto(prompt)
    
    print("\nTexto generado:")
    print("--------------")
    print(texto_generado)

