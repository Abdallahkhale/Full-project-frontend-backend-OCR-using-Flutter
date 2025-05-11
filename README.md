# OCR Web Application

## Project Overview

This project is a full-stack web application for performing Optical Character Recognition (OCR) on receipts. Users can capture receipts with their camera or upload image files, and the application will extract and display the text content.

### Key Features

- 📱 Responsive Flutter web interface
- 📷 Receipt capture via device camera
- 📤 Image upload functionality
- 🔍 Text extraction using Tesseract OCR
- 🖥️ FastAPI backend with image preprocessing
- 🌐 Cross-platform compatibility

### Tech Stack

- **Frontend**: Flutter Web
- **Backend**: FastAPI (Python)
- **OCR Engine**: Tesseract OCR
- **Image Processing**: OpenCV
- **Deployment**: Google Colab + ngrok (development)

## Project Structure

```
receipt-ocr/
├── ocr/              # Flutter web application
│   ├── web/
│   ├── lib/
│   │   └── main.dart      # Main Flutter application
│   └── pubspec.yaml       # Flutter dependencies
│
└── backend/               # FastAPI backend
    └── ocr_backend.ipynb            # Complete backend code for Colab
```

## Setup Instructions

### Frontend Setup

1. **Prerequisites**
   - Flutter SDK (2.0 or higher)
   - Dart (2.12 or higher)

2. **Installation**
   ```bash
   # Clone the repository
   git clone https://github.com/your-username/receipt-ocr.git
   cd receipt-ocr/frontend

   # Get dependencies
   flutter pub get

   # Run the web app in development mode
   flutter run -d chrome
   ```

3. **Build for production**
   ```bash
   flutter build web
   ```

### Backend Setup

#### Option 1: Run on Google Colab (Quickest for testing)

1. Open [Google Colab](https://colab.research.google.com/)
2. Create a new notebook
3. Copy and paste the entire content of `backend/app.py` into a cell
4. Run the cell and wait for installations to complete
5. Copy the generated ngrok URL (e.g., `https://xxxx-xx-xxx-xx-xxx.ngrok-free.app`)
6. Update the API URL in the frontend settings

#### Option 2: Run locally (For development)

1. **Prerequisites**
   - Python 3.7+
   - Tesseract OCR installed on your system

2. **Installation**
   ```bash
   # Create a virtual environment
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate

   # Install dependencies
   pip install fastapi uvicorn pyngrok pytesseract opencv-python Pillow pydantic python-multipart

   # Install Tesseract OCR (platform-specific)
   # Ubuntu: apt-get install tesseract-ocr
   # macOS: brew install tesseract
   # Windows: Download installer from https://github.com/UB-Mannheim/tesseract/wiki

   # Run the server
   uvicorn app:app --reload
   ```

3. **Expose local server with ngrok** (optional)
   ```bash
   # Install ngrok
   pip install pyngrok

   # Run in Python
   from pyngrok import ngrok
   ngrok_tunnel = ngrok.connect(8000)
   print(f"Public URL: {ngrok_tunnel.public_url}")
   ```

#### Option 3: Deploy to production

For a production environment, consider deploying:
- Frontend to Firebase Hosting, Netlify, or Vercel
- Backend to Heroku, Digital Ocean, or AWS

## Usage

1. Open the web application in your browser
2. Click "Capture" to use your device camera or "Upload" to select an image file
3. Wait for the OCR processing to complete
4. View the extracted text in the results section
5. The text can be selected and copied

## Configuration

### API URL Configuration

The application allows you to change the backend API URL through the settings menu:
1. Click the gear icon in the top right corner
2. Enter your backend URL (e.g., ngrok URL from Colab)
3. Click "Save"

### OCR Optimization

For better OCR results with different types of receipts, you may want to adjust the preprocessing parameters in `preprocess_image()` function:

```python
# For receipts with light text on dark background
binary = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 11, 2)

# For improving contrast
clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
gray = clahe.apply(gray)

# For more aggressive noise removal
denoised = cv2.fastNlMeansDenoising(binary, None, 15, 7, 21)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Tesseract OCR for the text recognition engine
- Flutter team for the amazing cross-platform framework
- FastAPI for simple yet powerful API framework
- OpenCV for image processing capabilities
