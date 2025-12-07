// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'editor_page.dart';
import 'restore_page.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Friendly Editor',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final bytes = await pickedFile.readAsBytes();
        final compressedBytes = await _compressImage(bytes);

        Navigator.pop(context); // Close loading dialog

        if (compressedBytes != null) {
          if (compressedBytes.length > 10 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image is too large (max 10MB)')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditorPage(imageBytes: compressedBytes),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<Uint8List?> _compressImage(Uint8List bytes) async {
    try {
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      
      // Resize only if necessary
      if (image.width > 1920 || image.height > 1080) {
        final resized = img.copyResize(image, width: 1920);
        return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      }
      return bytes;
    } catch (e) {
      return null;
    }
  }

  void _navigateToRestorePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RestorePage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: const Text(
                    'USER FRIENDLY EDITOR',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(2, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Enhance your images with AI-powered editing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: _pickImage,
                          child: _buildButton('Pick an image', const Color.fromARGB(255, 79, 59, 208)),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _navigateToRestorePage,
                          child: _buildButton('AI Face Enhancement', const Color.fromARGB(255, 95, 52, 215)),
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

  Widget _buildButton(String text, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}