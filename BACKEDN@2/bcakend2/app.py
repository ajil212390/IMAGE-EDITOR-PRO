from flask import Flask, request, jsonify, send_from_directory
import os
import cv2
from gfpgan import GFPGANer
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

UPLOAD_FOLDER = 'uploads'
RESULT_FOLDER = 'static/restored_images'
MODEL_PATH = 'models/GFPGANv1.4.pth'

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULT_FOLDER, exist_ok=True)

# Check if the model file exists
if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Model file not found at {MODEL_PATH}. Please download the model.")

# Load GFPGAN model
try:
    restorer = GFPGANer(model_path=MODEL_PATH, upscale=2, arch='clean', channel_multiplier=2)
    print("GFPGAN model loaded successfully!")
except Exception as e:
    print(f"Error loading GFPGAN model: {str(e)}")
    restorer = None

@app.route('/restore', methods=['POST'])
def restore():
    # Check if there's a file in the request
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    # Validate file format
    if not file.filename.lower().endswith(('.png', '.jpg', '.jpeg')):
        return jsonify({'error': 'Invalid file format. Only PNG, JPG, and JPEG are supported.'}), 400
    
    # Save uploaded image with a unique filename to prevent conflicts
    filename = f"input_{os.path.basename(file.filename)}"
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)
    
    # Load image
    img = cv2.imread(filepath)
    if img is None:
        return jsonify({'error': 'Invalid image format'}), 400
    
    try:
        # Check if the model is loaded
        if restorer is None:
            return jsonify({'error': 'GFPGAN model not loaded'}), 500
        
        # Fix the unpacking issue - GFPGAN might return different values based on version
        result = restorer.enhance(img, has_aligned=False, only_center_face=False, paste_back=True)
        
        # Handle different return formats from different GFPGAN versions
        if isinstance(result, tuple):
            if len(result) == 2:
                _, restored_img = result
            elif len(result) == 4:  # Some versions return 4 values
                _, _, restored_img, _ = result
            else:
                # If we can't unpack properly, just take the last element assuming it's the image
                restored_img = result[-1]
        else:
            # If not a tuple, assume result is the image directly
            restored_img = result
        
        # Save and return the restored image
        output_filename = f"restored_{filename}"
        output_path = os.path.join(RESULT_FOLDER, output_filename)
        
        # Ensure the restored image is properly formatted
        if restored_img is None:
            return jsonify({'error': 'Restoration failed - null result'}), 500
            
        cv2.imwrite(output_path, restored_img)
        
        # Return the restored image directly instead of a URL
        with open(output_path, 'rb') as f:
            restored_image_data = f.read()
        
        return restored_image_data, 200, {'Content-Type': 'image/jpeg'}
    
    except Exception as e:
        print(f"Error during restoration: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@app.route('/static/restored_images/<filename>', methods=['GET'])
def get_restored_image(filename):
    return send_from_directory(RESULT_FOLDER, filename)

if __name__ == '__main__':
    app.run(debug=True)