import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_web/image_picker_web.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Receipt OCR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: OCRScreen(),
    );
  }
}

class OCRScreen extends StatefulWidget {
  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  Uint8List? _imageBytes;
  String _imageUrl = '';
  String _ocrText = "";
  bool _isLoading = false;
  String _apiUrl = "https://1058-34-16-136-168.ngrok-free.app"; // Update with your ngrok URL

  Future<void> _pickImage() async {
    try {
      // ImagePickerWeb.getImageInfo returns a function that needs to be called
      final mediaInfo = await ImagePickerWeb.getImageInfo();
      if (mediaInfo != null) {
        setState(() {
          _imageBytes = mediaInfo.data;
          _imageUrl = mediaInfo.data != null ? 
              'data:image/jpeg;base64,${base64Encode(mediaInfo.data!)}' : '';
          _ocrText = '';
        });
        
        if (_imageBytes != null) {
          _processImageBase64(base64Encode(_imageBytes!));
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'))
      );
    }
  }

  Future<void> _captureImage() async {
    // Using the browser's camera
    try {
      final videoConstraints = {
        'video': true,
        'facingMode': 'environment'  // Use back camera if available
      };

      final mediaStream = await html.window.navigator.mediaDevices?.getUserMedia(videoConstraints);
      
      if (mediaStream != null) {
        // Create and show the camera interface
        _showCameraDialog(mediaStream);
      }
    } catch (e) {
      print('Error accessing camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not access camera. Please use upload instead.'))
      );
    }
  }

  void _showCameraDialog(html.MediaStream mediaStream) {
    final videoElement = html.VideoElement()
      ..srcObject = mediaStream
      ..autoplay = true;

    final canvasElement = html.CanvasElement();

    // Create a unique ID for the video element
    final videoId = 'video-element-${DateTime.now().millisecondsSinceEpoch}';
    
    // Inject the video element into the DOM
    videoElement.id = videoId;
    html.document.body?.append(videoElement);
    videoElement.style.display = 'none'; // Hide it from view
    
    // After a short delay to let the video initialize
    Future.delayed(Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Take Photo'),
          content: Container(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 300,
                  width: 400,
                  color: Colors.grey[200],
                  child: Center(
                    child: Text('Camera preview not available in dialog. Click Capture to take a photo.'),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Capture'),
                  onPressed: () {
                    // Capture the current frame
                    canvasElement.width = videoElement.videoWidth;
                    canvasElement.height = videoElement.videoHeight;
                    canvasElement.context2D.drawImage(videoElement, 0, 0);
                    final imageDataUrl = canvasElement.toDataUrl('image/png');
                    
                    // Stop the camera
                    mediaStream.getTracks().forEach((track) => track.stop());
                    
                    // Process the captured image
                    setState(() {
                      _imageUrl = imageDataUrl;
                    });
                    
                    Navigator.of(context).pop();
                    
                    // Process the base64 image
                    if (imageDataUrl.contains(',')) {
                      final base64 = imageDataUrl.split(',')[1];
                      _processImageBase64(base64);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                // Stop the camera
                mediaStream.getTracks().forEach((track) => track.stop());
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ).then((_) {
        // Clean up - remove the video element when dialog is closed
        videoElement.remove();
      });
    });
  }
  
  // Process base64 image directly
  Future<void> _processImageBase64(String base64Image) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Send request with base64 data
      final response = await http.post(
        Uri.parse('$_apiUrl/ocr/base64/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image})
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        setState(() {
          _ocrText = result['text'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _ocrText = "Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _ocrText = "Error: $e";
        _isLoading = false;
      });
    }
  }
  
  void _updateApiUrl(String newUrl) {
    setState(() {
      _apiUrl = newUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Web Receipt OCR Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(  // Added ScrollView to fix overflow
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Upload or Capture a Receipt',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        
                        // Image preview - Added constraints to prevent overflow
                        if (_imageUrl.isNotEmpty)
                          Container(
                            constraints: BoxConstraints(maxHeight: 300),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(Icons.image, size: 80, color: Colors.grey),
                            ),
                          ),
                        
                        SizedBox(height: 20),
                        
                        // Button row - Made responsive
                        Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.camera_alt),
                              label: Text('Capture'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: _captureImage,
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.upload_file),
                              label: Text('Upload'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: _pickImage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // OCR Results
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OCR Results',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        
                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _ocrText.isEmpty ? 'OCR text will appear here' : _ocrText,
                              style: TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSettingsDialog() {
    final TextEditingController controller = TextEditingController(text: _apiUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'API URL',
            hintText: 'Enter your ngrok URL',
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              _updateApiUrl(controller.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}