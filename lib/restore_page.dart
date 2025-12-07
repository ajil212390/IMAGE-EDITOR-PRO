import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class RestorePage extends StatefulWidget {
  final String serverUrl;
  
  const RestorePage({super.key, this.serverUrl = 'http://127.0.0.1:5000'});

  @override
  // ignore: library_private_types_in_public_api
  _RestorePageState createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  Uint8List? _selectedImage;
  Uint8List? _restoredImage;
  bool _isLoading = false;
  String _statusMessage = "Select an image to restore";
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _restoredImage = null;
          _statusMessage = "Image selected. Ready to restore.";
        });
      }
    } catch (e) {
      _showError("Image selection failed: ${e.toString()}");
    }
  }

  Future<void> _restoreImage() async {
    if (_selectedImage == null) {
      _showError("Please select an image first");
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Processing image...";
    });

    try {
      final uri = Uri.parse('${widget.serverUrl}/restore');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedImage!,
          filename: 'image.jpg',
        ));

      final response = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          setState(() => _isLoading = false);
          throw Exception('''
Server connection timeout. Please check:
1. Server is running at ${widget.serverUrl}
2. Your device is on the same network
3. Firewall allows port 5000
4. Server is accessible from this device''');
        },
      );

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        setState(() {
          _restoredImage = bytes;
          _statusMessage = "Restoration successful!";
        });
      } else {
        final error = await response.stream.bytesToString();
        throw Exception('Server error: ${response.statusCode} - $error');
      }
    } on SocketException catch (e) {
      _showError("Network Error: ${e.message}\nCheck your connection and server status");
    } on TimeoutException catch (_) {
      _showError("Connection timed out. Check server availability.");
    } catch (e) {
      _showError("Restoration failed: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.replaceAll('Exception:', '')
                .replaceAll('ClientException', '')
                .trim(),
        ),
        backgroundColor: Colors.red[800],
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _saveImage() async {
    if (_restoredImage == null) return;

    try {
      final blob = html.Blob([_restoredImage], 'image/jpeg');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..download = 'restored_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..style.display = 'none';
      
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image download started"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError("Couldn't save image: ${e.toString()}");
    }
  }

  void _showFullImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: PhotoView(
            imageProvider: MemoryImage(imageBytes),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Face Restoration'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          if (_restoredImage != null)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _saveImage,
              tooltip: 'Download Image',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF263238), Color(0xFF000000)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Main content - side by side
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Original Image Column
                        Expanded(
                          child: _buildImageCard(
                            title: "Original Image",
                            image: _selectedImage,
                            buttonText: "SELECT IMAGE",
                            buttonColor: Colors.red[800]!,
                            onPressed: _pickImage,
                            borderColor: Colors.red[800]!,
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Restored Image Column
                        Expanded(
                          child: _buildImageCard(
                            title: "Enhanced Image",
                            image: _restoredImage,
                            buttonText: "Enhance Faces",
                            buttonColor: Colors.green[600]!,
                            onPressed: _isLoading ? null : _restoreImage,
                            borderColor: Colors.green[600]!,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required Uint8List? image,
    required String buttonText,
    required Color buttonColor,
    required Color borderColor,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Card(
      color: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: image != null
                    ? GestureDetector(
                        onTap: () => _showFullImage(image),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          title == "Original Image" 
                              ? Icons.image 
                              : Icons.auto_awesome,
                          size: 60,
                          color: Colors.white24,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        buttonText,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}