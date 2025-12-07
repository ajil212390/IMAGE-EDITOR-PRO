import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:http/http.dart' as http;

class ResizableImage extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback onDelete;

  const ResizableImage({
    required this.imageBytes,
    required this.onDelete,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ResizableImageState createState() => _ResizableImageState();
}

class _ResizableImageState extends State<ResizableImage> {
  double x = 100;
  double y = 100;
  double width = 200;
  double height = 200;
  double rotationAngle = 0.0;
  bool isSelected = false;
  double opacity = 1.0;
  
  // Filter properties
  ImageFilter currentFilter = ImageFilter.none;
  
  // Background removal
  bool isBackgroundRemoved = false;
  Uint8List? processedImage;
  bool isProcessing = false;
  
  // Crop properties
  bool isCropping = false;
  Rect cropRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    // Initialize cropRect to full image
    cropRect = Rect.fromLTWH(0, 0, width, height);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x.clamp(0, MediaQuery.of(context).size.width - width),
      top: y.clamp(0, MediaQuery.of(context).size.height - height),
      child: GestureDetector(
        onTap: () => setState(() {
          if (isCropping) {
            // Exit crop mode if tapping outside crop handles
            finishCrop();
          } else {
            isSelected = !isSelected;
          }
        }),
        onLongPress: () => showDeleteDialog(),
        onPanUpdate: (details) {
          if (!isCropping) {
            setState(() {
              x += details.delta.dx;
              y += details.delta.dy;
            });
          }
        },
        child: Transform.rotate(
          angle: rotationAngle,
          child: Stack(
            children: [
              Opacity(
                opacity: opacity,
                child: Container(
                  width: width,
                  height: height,
                  decoration: isSelected
                      ? BoxDecoration(
                          border: Border.all(color: Colors.blue),
                        )
                      : null,
                  child: isCropping
                      ? buildCropView()
                      : ImageFilters(
                          image: processedImage ?? widget.imageBytes,
                          filter: currentFilter,
                        ),
                ),
              ),
              if (isSelected && !isCropping) ...[
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: resizeHandler,
                    child: const Tooltip(
                      message: "Resize",
                      child: Icon(Icons.zoom_out_map, color: Colors.blue, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onPanUpdate: rotateHandler,
                    child: const Tooltip(
                      message: "Rotate",
                      child: Icon(Icons.rotate_right, color: Colors.green, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Row(
                    children: [
                      Tooltip(
                        message: "Adjust Opacity",
                        child: IconButton(
                          icon: const Icon(Icons.opacity, color: Colors.purple, size: 20),
                          onPressed: () => showOpacityDialog(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "Apply Filter",
                        child: IconButton(
                          icon: const Icon(Icons.filter, color: Colors.orange, size: 20),
                          onPressed: () => _showFilterMenu(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "Remove Background",
                        child: IconButton(
                          icon: const Icon(Icons.auto_fix_high, color: Colors.indigo, size: 20),
                          onPressed: () => removeBackground(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "Crop Image",
                        child: IconButton(
                          icon: const Icon(Icons.crop, color: Colors.teal, size: 20),
                          onPressed: () => startCrop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isCropping) ...[
                Positioned(
                  right: 0,
                  top: 0,
                  child: Row(
                    children: [
                      Tooltip(
                        message: "Apply Crop",
                        child: IconButton(
                          icon: const Icon(Icons.check, color: Colors.green, size: 20),
                          onPressed: () => applyCrop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "Cancel",
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 20),
                          onPressed: () => cancelCrop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isProcessing)
                Container(
                  width: width,
                  height: height,
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCropView() {
    return Stack(
      children: [
        // The image to crop
        ClipRect(
          child: ImageFilters(
            image: processedImage ?? widget.imageBytes,
            filter: currentFilter,
          ),
        ),
        
        // Crop overlay
        CustomPaint(
          size: Size(width, height),
          painter: CropPainter(cropRect),
        ),
        
        // Crop handles
        ...buildCropHandles(),
      ],
    );
  }

  List<Widget> buildCropHandles() {
    return [
      // Top left
      Positioned(
        left: cropRect.left - 10,
        top: cropRect.top - 10,
        child: buildCropHandle(
          onDrag: (dx, dy) {
            setState(() {
              cropRect = Rect.fromLTRB(
                (cropRect.left + dx).clamp(0, cropRect.right - 20),
                (cropRect.top + dy).clamp(0, cropRect.bottom - 20),
                cropRect.right,
                cropRect.bottom,
              );
            });
          },
        ),
      ),
      // Top right
      Positioned(
        left: cropRect.right - 10,
        top: cropRect.top - 10,
        child: buildCropHandle(
          onDrag: (dx, dy) {
            setState(() {
              cropRect = Rect.fromLTRB(
                cropRect.left,
                (cropRect.top + dy).clamp(0, cropRect.bottom - 20),
                (cropRect.right + dx).clamp(cropRect.left + 20, width),
                cropRect.bottom,
              );
            });
          },
        ),
      ),
      // Bottom left
      Positioned(
        left: cropRect.left - 10,
        top: cropRect.bottom - 10,
        child: buildCropHandle(
          onDrag: (dx, dy) {
            setState(() {
              cropRect = Rect.fromLTRB(
                (cropRect.left + dx).clamp(0, cropRect.right - 20),
                cropRect.top,
                cropRect.right,
                (cropRect.bottom + dy).clamp(cropRect.top + 20, height),
              );
            });
          },
        ),
      ),
      // Bottom right
      Positioned(
        left: cropRect.right - 10,
        top: cropRect.bottom - 10,
        child: buildCropHandle(
          onDrag: (dx, dy) {
            setState(() {
              cropRect = Rect.fromLTRB(
                cropRect.left,
                cropRect.top,
                (cropRect.right + dx).clamp(cropRect.left + 20, width),
                (cropRect.bottom + dy).clamp(cropRect.top + 20, height),
              );
            });
          },
        ),
      ),
    ];
  }

  Widget buildCropHandle({
    required Function(double dx, double dy) onDrag,
  }) {
    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
        ),
      ),
    );
  }

  void startCrop() {
    setState(() {
      isCropping = true;
      cropRect = Rect.fromLTWH(width * 0.1, height * 0.1, width * 0.8, height * 0.8);
    });
  }

  void cancelCrop() {
    setState(() {
      isCropping = false;
    });
  }

  void finishCrop() {
    setState(() {
      isCropping = false;
    });
  }

  Future<void> applyCrop() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Create an image from the original bytes
      final codec = await ui.instantiateImageCodec(processedImage ?? widget.imageBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // Create a picture recorder to draw our cropped image
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      
      // Calculate scale factors
      final scaleX = originalImage.width / width;
      final scaleY = originalImage.height / height;
      
      // Draw the cropped portion
      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(
          cropRect.left * scaleX,
          cropRect.top * scaleY,
          cropRect.width * scaleX,
          cropRect.height * scaleY,
        ),
        Rect.fromLTWH(0, 0, cropRect.width * scaleX, cropRect.height * scaleY),
        Paint(),
      );
      
      // Convert to an image
      final picture = pictureRecorder.endRecording();
      final croppedImage = await picture.toImage(
        (cropRect.width * scaleX).toInt(),
        (cropRect.height * scaleY).toInt(),
      );
      
      // Convert to bytes
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      final croppedBytes = byteData!.buffer.asUint8List();
      
      // Update state
      setState(() {
        processedImage = croppedBytes;
        width = cropRect.width;
        height = cropRect.height;
        isCropping = false;
        isProcessing = false;
      });
      
      // Clean up
      originalImage.dispose();
      croppedImage.dispose();
      
    } catch (e) {
      setState(() {
        isProcessing = false;
        isCropping = false;
      });
      
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to crop image: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showFilterMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    
    showMenu<ImageFilter>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + 30,
        offset.dx + 200,
        offset.dy,
      ),
      items: ImageFilter.values.map((filter) {
        return PopupMenuItem<ImageFilter>(
          value: filter,
          child: Text(_getFilterName(filter)),
        );
      }).toList(),
    ).then((selectedFilter) {
      if (selectedFilter != null) {
        setState(() {
          currentFilter = selectedFilter;
        });
      }
    });
  }

  Future<void> removeBackground() async {
    if (isBackgroundRemoved) {
      // Reset to original image
      setState(() {
        processedImage = null;
        isBackgroundRemoved = false;
      });
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // TODO: Replace with your actual Flask API endpoint
      final apiUrl = 'http://127.0.0.1:5001/remove-background';
      
      // Convert image bytes to base64
      final base64Image = base64Encode(widget.imageBytes);
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final processedImageBase64 = responseData['processed_image'];
        final processedImageBytes = base64Decode(processedImageBase64);
        
        setState(() {
          processedImage = processedImageBytes;
          isBackgroundRemoved = true;
          isProcessing = false;
        });
      } else {
        setState(() {
          isProcessing = false;
        });
        
        // Show error dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to remove background. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void resizeHandler(DragUpdateDetails details) {
    setState(() {
      width += details.delta.dx;
      height += details.delta.dy;
      
      // Minimum size constraints
      if (width < 50) width = 50;
      if (height < 50) height = 50;
    });
  }

  void rotateHandler(DragUpdateDetails details) {
    setState(() => rotationAngle += details.delta.dx * 0.01);
  }

  void showOpacityDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Image Opacity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Adjust Opacity'),
                Slider(
                  value: opacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) {
                    setStateDialog(() => opacity = value);
                    setState(() => opacity = value);
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transparent'),
                    Text('Opaque'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFilterName(ImageFilter filter) {
    switch (filter) {
      case ImageFilter.none:
        return 'Normal';
      case ImageFilter.grayscale:
        return 'Grayscale';
      case ImageFilter.sepia:
        return 'Sepia';
      case ImageFilter.invert:
        return 'Invert';
      case ImageFilter.vintage:
        return 'Vintage';
      case ImageFilter.coldBlue:
        return 'Cold Blue';
      case ImageFilter.warmOrange:
        return 'Warm Orange';
    }
  }
}

// Custom painter for crop overlay
class CropPainter extends CustomPainter {
  final Rect cropRect;
  
  CropPainter(this.cropRect);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw semi-transparent overlay for the areas outside the crop rectangle
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    // Top region
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, cropRect.top),
      paint,
    );
    
    // Bottom region
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.bottom, size.width, size.height - cropRect.bottom),
      paint,
    );
    
    // Left region
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      paint,
    );
    
    // Right region
    canvas.drawRect(
      Rect.fromLTWH(cropRect.right, cropRect.top, size.width - cropRect.right, cropRect.height),
      paint,
    );
    
    // Draw crop rectangle border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(cropRect, borderPaint);
    
    // Draw grid lines (rule of thirds)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Vertical lines
    final thirdWidth = cropRect.width / 3;
    canvas.drawLine(
      Offset(cropRect.left + thirdWidth, cropRect.top),
      Offset(cropRect.left + thirdWidth, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.right - thirdWidth, cropRect.top),
      Offset(cropRect.right - thirdWidth, cropRect.bottom),
      gridPaint,
    );
    
    // Horizontal lines
    final thirdHeight = cropRect.height / 3;
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdHeight),
      Offset(cropRect.right, cropRect.top + thirdHeight),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.bottom - thirdHeight),
      Offset(cropRect.right, cropRect.bottom - thirdHeight),
      gridPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ImageFilters extends StatelessWidget {
  final Uint8List image;
  final ImageFilter filter;

  const ImageFilters({
    required this.image,
    required this.filter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _getColorFilter(),
      child: Image.memory(
        image,
        fit: BoxFit.cover,
      ),
    );
  }

  ColorFilter _getColorFilter() {
// Fixed intensity
    
    switch (filter) {
      case ImageFilter.none:
        return const ColorFilter.mode(Colors.transparent, BlendMode.srcOver);
      case ImageFilter.grayscale:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilter.sepia:
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilter.invert:
        final matrix = List<double>.filled(20, 0);
        
        // Apply full inversion
        matrix[0] = matrix[6] = matrix[12] = -1;
        matrix[4] = matrix[9] = matrix[14] = 1;
        matrix[18] = 1;
        
        return ColorFilter.matrix(matrix);
      case ImageFilter.vintage:
        return const ColorFilter.matrix([
          0.9, 0.3, 0.3, 0, 0,
          0.3, 0.8, 0.3, 0, 0,
          0.2, 0.2, 0.7, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilter.coldBlue:
        return const ColorFilter.matrix([
          0.8, 0, 0, 0, 0,
          0, 0.9, 0, 0, 0,
          0, 0, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilter.warmOrange:
        return const ColorFilter.matrix([
          1.2, 0, 0, 0, 0.1,
          0, 1.1, 0, 0, 0.1,
          0, 0, 0.8, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }
}

enum ImageFilter {
  none,
  grayscale,
  sepia,
  invert,
  vintage,
  coldBlue,
  warmOrange,
}