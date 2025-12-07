from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import io
import numpy as np
import cv2
from rembg import remove
from PIL import Image

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/remove-background', methods=['POST'])
def remove_background():
    try:
        # Get JSON data from request
        data = request.json
        
        if not data or 'image' not in data:
            return jsonify({'error': 'No image data provided'}), 400
        
        # Decode base64 image
        image_data = data['image']
        # Remove data:image/jpeg;base64, prefix if it exists
        if ',' in image_data:
            image_data = image_data.split(',')[1]
            
        # Decode base64 to binary
        image_bytes = base64.b64decode(image_data)
        
        # Convert to PIL Image
        input_image = Image.open(io.BytesIO(image_bytes))
        
        # Use rembg to remove background
        output_image = remove(input_image)
        
        # Convert back to base64
        buffered = io.BytesIO()
        output_image.save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')
        
        return jsonify({'processed_image': img_str})
    
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        return jsonify({'error': str(e)}), 500

# Optional: Alternative implementation using OpenCV if you prefer not to use rembg
@app.route('/remove-background-opencv', methods=['POST'])
def remove_background_opencv():
    try:
        # Get JSON data from request
        data = request.json
        
        if not data or 'image' not in data:
            return jsonify({'error': 'No image data provided'}), 400
        
        # Decode base64 image
        image_data = data['image']
        # Remove data:image/jpeg;base64, prefix if it exists
        if ',' in image_data:
            image_data = image_data.split(',')[1]
            
        # Decode base64 to binary
        image_bytes = base64.b64decode(image_data)
        
        # Convert to OpenCV image
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # Convert to RGBA to preserve transparency
        img_rgba = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
        
        # Simple background removal using color thresholding
        # Note: This is a simplified example - you might want to use more sophisticated methods
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        _, thresh = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)
        
        # Apply the mask
        img_rgba[:, :, 3] = thresh
        
        # Convert back to base64
        is_success, buffer = cv2.imencode(".png", img_rgba)
        if not is_success:
            return jsonify({'error': 'Failed to encode image'}), 500
            
        img_str = base64.b64encode(buffer).decode('utf-8')
        
        return jsonify({'processed_image': img_str})
    
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)