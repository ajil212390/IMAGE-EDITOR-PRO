// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'resizable_image.dart';
import 'resizable_text.dart';
import 'editor_state.dart';
import 'adjustment_dialog.dart';
import 'crop_painter.dart' as crop_painter; // Ensure this file contains the definition of CropPainter

class EditorPage extends StatefulWidget {
  final Uint8List imageBytes;

  const EditorPage({super.key, required this.imageBytes});

  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final GlobalKey _repaintKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();
  Color textColor = Colors.white;
  String selectedFont = 'Roboto';
  List<ResizableImage> imageWidgets = [];
  List<ResizableText> textWidgets = [];
  bool isProcessing = false;
  Uint8List? editedImageBytes;
  String? errorMessage;
  List<EditorState> history = [];
  int currentHistoryIndex = -1;
  ColorFilter? currentFilter;
  
  // Crop related variables
  bool isCropping = false;
  Rect cropRect = Rect.zero;
  Offset? _startDrag;
  Offset? _currentDrag;
  int? _resizeCorner;
  Size? _imageSize;
  ui.Image? _originalImage;
  bool _isImageLoaded = false;

  // Image adjustment values
  double brightness = 0.0;
  double contrast = 1.0;
  double saturation = 1.0;
  double hue = 0.0;
  double whiteBalance = 0.0;
  double vignette = 0.0;
  double sharpness = 0.0;
  double tint = 0.0;
  double shadows = 0.0;
  double highlights = 0.0;

  @override
  void initState() {
    super.initState();
    editedImageBytes = widget.imageBytes;
    _addToHistory();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (editedImageBytes != null) {
      final codec = await ui.instantiateImageCodec(editedImageBytes!);
      final frameInfo = await codec.getNextFrame();
      setState(() {
        _originalImage = frameInfo.image;
        _imageSize = Size(_originalImage!.width.toDouble(), _originalImage!.height.toDouble());
        _isImageLoaded = true;
        cropRect = Rect.fromLTWH(0, 0, _imageSize!.width, _imageSize!.height);
      });
    }
  }

  void _addToHistory() {
    if (currentHistoryIndex < history.length - 1) {
      history = history.sublist(0, currentHistoryIndex + 1);
    }
    history.add(EditorState(
      imageBytes: editedImageBytes!,
      imageWidgets: List.from(imageWidgets),
      textWidgets: List.from(textWidgets),
      filter: currentFilter,
    ));
    currentHistoryIndex = history.length - 1;
  }

  void _undo() {
    if (currentHistoryIndex > 0) {
      setState(() {
        currentHistoryIndex--;
        _applyHistoryState(history[currentHistoryIndex]);
      });
    }
  }

  void _redo() {
    if (currentHistoryIndex < history.length - 1) {
      setState(() {
        currentHistoryIndex++;
        _applyHistoryState(history[currentHistoryIndex]);
      });
    }
  }

  void _applyHistoryState(EditorState state) {
    editedImageBytes = state.imageBytes;
    imageWidgets = List.from(state.imageWidgets);
    textWidgets = List.from(state.textWidgets);
    currentFilter = state.filter;
    _loadImage();
  }

  Future<void> _downloadImage() async {
    try {
      final boundary = _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'edited_image_${DateTime.now().millisecondsSinceEpoch}.png')
          ..style.display = 'none';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        if (await _requestPermission()) {
          final directory = await getDownloadsDirectory();
          if (directory == null) {
            throw Exception("Couldn't get downloads directory");
          }
          
          final file = File('${directory.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(bytes);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to ${file.path}')),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to save image: ${e.toString()}');
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }
    return true;
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        imageWidgets.add(ResizableImage(
          imageBytes: imageBytes,
          onDelete: () {
            setState(() => imageWidgets.removeLast());
            _addToHistory();
          },
        ));
        _addToHistory();
      });
    }
  }

  void _addText() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Text'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(hintText: 'Enter text'),
              ),
              const SizedBox(height: 10),
              ColorPicker(
                pickerColor: textColor,
                onColorChanged: (color) => setStateDialog(() => textColor = color),
                showLabel: false,
              ),
              DropdownButton<String>(
                value: selectedFont,
                items: [
                  'Roboto', 'Lobster', 'Oswald', 'Pacifico', 'Raleway',
                  'Montserrat', 'Poppins', 'Open Sans', 'Playfair Display',
                  'Dancing Script', 'Bebas Neue', 'Merriweather', 'EB Garamond',
                  'Lora', 'PT Serif', 'Inter', 'Nunito', 'Work Sans', 'Fira Sans',
                  'Exo 2', 'Anton', 'Abril Fatface', 'Barlow Condensed',
                  'Indie Flower', 'Caveat', 'Satisfy', 'Space Mono',
                  'Inconsolata', 'Roboto Mono', 'Fira Code'
                ].map((font) => DropdownMenuItem(
                  value: font,
                  child: Text(font, style: GoogleFonts.getFont(font)),
                )).toList(),
                onChanged: (value) => setStateDialog(() => selectedFont = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  textWidgets.add(ResizableText(
                    text: textController.text,
                    color: textColor,
                    fontFamily: selectedFont,
                    onDelete: () {
                      setState(() => textWidgets.removeLast());
                      _addToHistory();
                    },
                  ));
                  _addToHistory();
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _startCropping() {
    if (!_isImageLoaded) {
      _showErrorDialog('Image is still loading. Please wait.');
      return;
    }

    setState(() {
      isCropping = true;
      final width = _imageSize!.width * 0.8;
      final height = _imageSize!.height * 0.8;
      cropRect = Rect.fromCenter(
        center: Offset(_imageSize!.width / 2, _imageSize!.height / 2),
        width: width,
        height: height,
      );
    });
  }

  void _cancelCropping() {
    setState(() {
      isCropping = false;
    });
  }

  Future<void> _applyCrop() async {
    if (!_isImageLoaded || _originalImage == null) {
      _showErrorDialog('Image not loaded properly');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      final imageCanvas = Rect.fromLTWH(0, 0, cropRect.width, cropRect.height);
      
      canvas.drawImageRect(
        _originalImage!,
        cropRect,
        imageCanvas,
        Paint(),
      );
      
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        cropRect.width.toInt(),
        cropRect.height.toInt(),
      );
      
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final croppedBytes = byteData!.buffer.asUint8List();
      
      setState(() {
        editedImageBytes = croppedBytes;
        isCropping = false;
        isProcessing = false;
        _addToHistory();
      });
      
      _loadImage();
    } catch (e) {
      setState(() {
        isProcessing = false;
        isCropping = false;
      });
      _showErrorDialog('Failed to crop image: ${e.toString()}');
    }
  }

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    if (!isCropping) return;
    
    final imageRect = _getImageRect(constraints);
    final localPosition = _getLocalPosition(details.localPosition, imageRect);
    
    _startDrag = localPosition;
    _resizeCorner = null;
    
    final cornerSize = math.min(_imageSize!.width, _imageSize!.height) * 0.08;
    
    if ((localPosition - cropRect.topLeft).distance < cornerSize) {
      _resizeCorner = 0;
    } 
    else if ((localPosition - cropRect.topRight).distance < cornerSize) {
      _resizeCorner = 1;
    } 
    else if ((localPosition - cropRect.bottomLeft).distance < cornerSize) {
      _resizeCorner = 2;
    } 
    else if ((localPosition - cropRect.bottomRight).distance < cornerSize) {
      _resizeCorner = 3;
    }
    
    setState(() {
      _currentDrag = localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!isCropping || _startDrag == null) return;
    
    final imageRect = _getImageRect(constraints);
    final localPosition = _getLocalPosition(details.localPosition, imageRect);
    
    setState(() {
      _currentDrag = localPosition;
      
      if (_resizeCorner != null) {
        switch (_resizeCorner) {
          case 0:
            cropRect = Rect.fromPoints(
              Offset(
                math.max(0, math.min(cropRect.right - 40, localPosition.dx)),
                math.max(0, math.min(cropRect.bottom - 40, localPosition.dy)),
              ),
              cropRect.bottomRight,
            );
            break;
          case 1:
            cropRect = Rect.fromPoints(
              Offset(
                cropRect.left,
                math.max(0, math.min(cropRect.bottom - 40, localPosition.dy)),
              ),
              Offset(
                math.min(_imageSize!.width, math.max(cropRect.left + 40, localPosition.dx)),
                cropRect.bottom,
              ),
            );
            break;
          case 2:
            cropRect = Rect.fromPoints(
              Offset(
                math.max(0, math.min(cropRect.right - 40, localPosition.dx)),
                cropRect.top,
              ),
              Offset(
                cropRect.right,
                math.min(_imageSize!.height, math.max(cropRect.top + 40, localPosition.dy)),
              ),
            );
            break;
          case 3:
            cropRect = Rect.fromPoints(
              cropRect.topLeft,
              Offset(
                math.min(_imageSize!.width, math.max(cropRect.left + 40, localPosition.dx)),
                math.min(_imageSize!.height, math.max(cropRect.top + 40, localPosition.dy)),
              ),
            );
            break;
        }
      } else {
        final delta = localPosition - _startDrag!;
        final newTopLeft = cropRect.topLeft + delta;
        
        var adjustedTopLeft = Offset(
          math.max(0, math.min(_imageSize!.width - cropRect.width, newTopLeft.dx)),
          math.max(0, math.min(_imageSize!.height - cropRect.height, newTopLeft.dy)),
        );
        
        cropRect = Rect.fromLTWH(
          adjustedTopLeft.dx,
          adjustedTopLeft.dy,
          cropRect.width,
          cropRect.height,
        );
        
        _startDrag = localPosition;
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!isCropping) return;
    
    setState(() {
      _startDrag = null;
      _currentDrag = null;
      _resizeCorner = null;
    });
  }

  Offset _getLocalPosition(Offset position, Rect imageRect) {
    final scaleX = _imageSize!.width / imageRect.width;
    final scaleY = _imageSize!.height / imageRect.height;
    
    return Offset(
      (position.dx - imageRect.left) * scaleX,
      (position.dy - imageRect.top) * scaleY,
    );
  }

  Rect _getImageRect(BoxConstraints constraints) {
    if (_imageSize == null) return Rect.zero;
    
    final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
    final double scale = math.min(
      viewportSize.width / _imageSize!.width,
      viewportSize.height / _imageSize!.height,
    );
    
    final scaledWidth = _imageSize!.width * scale;
    final scaledHeight = _imageSize!.height * scale;
    
    return Rect.fromCenter(
      center: Offset(viewportSize.width / 2, viewportSize.height / 2),
      width: scaledWidth,
      height: scaledHeight,
    );
  }

  Widget _buildCropOverlay(BoxConstraints constraints) {
    if (!_isImageLoaded) return Container();
    
    final imageRect = _getImageRect(constraints);
    
    return CustomPaint(
      size: Size(constraints.maxWidth, constraints.maxHeight),
      painter: crop_painter.CropPainter(
        imageRect: imageRect,
        cropRect: cropRect,
        imageSize: _imageSize!,
        corner: _resizeCorner,
        dragPoint: _currentDrag,
      ),
    );
  }

  Future<void> _removeBackground() async {
    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      final base64Image = base64Encode(editedImageBytes!);
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5001/remove-background'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final processedImageBytes = base64Decode(responseData['processed_image']);
        setState(() => editedImageBytes = processedImageBytes);
        _addToHistory();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Failed to process image: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  void _applyFilter(ColorFilter? filter) {
    setState(() {
      currentFilter = filter;
      _addToHistory();
    });
  }

  void _showAdjustmentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AdjustmentDialog(
        initialBrightness: brightness,
        initialContrast: contrast,
        initialSaturation: saturation,
        initialHue: hue,
        initialWhiteBalance: whiteBalance,
        initialVignette: vignette,
        initialSharpness: sharpness,
        initialTint: tint,
        initialShadows: shadows,
        initialHighlights: highlights,
        onAdjustmentsChanged: (filter) {
          setState(() {
            currentFilter = filter;
          });
        },
        onReset: () {
          setState(() {
            brightness = 0.0;
            contrast = 1.0;
            saturation = 1.0;
            hue = 0.0;
            whiteBalance = 0.0;
            vignette = 0.0;
            sharpness = 0.0;
            tint = 0.0;
            shadows = 0.0;
            highlights = 0.0;
            currentFilter = null;
          });
          _addToHistory();
        },
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo, tooltip: 'Undo'),
          IconButton(icon: const Icon(Icons.redo), onPressed: _redo, tooltip: 'Redo'),
          IconButton(icon: const Icon(Icons.save), onPressed: _downloadImage, tooltip: 'Save Image'),
          if (isCropping) ...[
            IconButton(icon: const Icon(Icons.check), onPressed: _applyCrop, tooltip: 'Apply Crop'),
            IconButton(icon: const Icon(Icons.close), onPressed: _cancelCropping, tooltip: 'Cancel Crop'),
          ],
        ],
      ),
      body: RepaintBoundary(
        key: _repaintKey,
        child: Stack(
          children: [
            RepaintBoundary(
              key: _imageKey,
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Center(
                      child: isProcessing
                          ? _buildProcessingIndicator()
                          : editedImageBytes != null
                              ? ColorFiltered(
                                  colorFilter: currentFilter ?? const ColorFilter.matrix([
                                    1, 0, 0, 0, 0,
                                    0, 1, 0, 0, 0,
                                    0, 0, 1, 0, 0,
                                    0, 0, 0, 1, 0,
                                  ]),
                                  child: Image.memory(editedImageBytes!),
                                )
                              : Container(),
                    ),
                    if (!isCropping) ...[
                      ...imageWidgets,
                      ...textWidgets,
                    ],
                  ],
                ),
              ),
            ),
            if (isCropping && _isImageLoaded)
              LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: (details) => _handlePanStart(details, constraints),
                    onPanUpdate: (details) => _handlePanUpdate(details, constraints),
                    onPanEnd: _handlePanEnd,
                    child: _buildCropOverlay(constraints),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            PopupMenuButton<ColorFilter?>(
              icon: const Icon(Icons.filter),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ]),
                  child: const Text('Grayscale'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    0.2, 0.2, 0.5, 0, 0,
                    0.2, 0.3, 0.7, 0, 0,
                    0.2, 0.3, 1.5, 0, 0,
                    0,   0,   0,   1, 0,
                  ]),
                  child: const Text('Deep Blue'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    1.2, -0.1, -0.1, 0, 10,
                    0.1,  1.0, -0.1, 0, 10,
                    -0.1, 0.1,  1.2, 0, 10,
                    0,    0,    0,   1, 0,
                  ]),
                  child: const Text('Vintage Film'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    1.8, -0.8, -0.8, 0, 0,
                    -0.8, 1.8, -0.8, 0, 0,
                    -0.8, -0.8, 1.8, 0, 0,
                    0,    0,    0,   1, 0,
                  ]),
                  child: const Text('Deep Black Mode'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    1.2, -0.3, -0.3, 0, -30,
                    -0.3, 1.2, -0.3, 0, -30,
                    -0.3, -0.3, 1.2, 0, -30,
                    0,    0,    0,   1, 0,
                  ]),
                  child: const Text('Film Noir'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    0.8, -0.2, -0.2, 0, -20,
                    -0.2, 0.8, -0.2, 0, -20,
                    -0.2, -0.2, 0.8, 0, -20,
                    0,    0,    0,   1, 0,
                  ]),
                  child: const Text('Low-Key B&W'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    0.393, 0.769, 0.189, 0, 0,
                    0.349, 0.686, 0.168, 0, 0,
                    0.272, 0.534, 0.131, 0, 0,
                    0,     0,     0,     1, 0,
                  ]),
                  child: const Text('Sepia'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    1.2, 0.2, 0.2, 0, 0,
                    0.2, 1.0, 0.2, 0, 0,
                    0.2, 0.2, 0.8, 0, 0,
                    0,   0,   0,   1, 0,
                  ]),
                  child: const Text('Warm Red Tint'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    0.8, 0.1, 0.1, 0, 0,
                    0.1, 1.2, 0.1, 0, 0,
                    0.1, 0.1, 0.8, 0, 0,
                    0,   0,   0,   1, 0,
                  ]),
                  child: const Text('Green Tint'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    1.2, -0.2, 0.1, 0, 0,
                    0.1, 1.0, -0.1, 0, 0,
                    -0.1, 0.2, 1.2, 0, 0,
                    0,    0,   0,   1, 0,
                  ]),
                  child: const Text('Old Film'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    2, 0, 0, 0, -255,
                    0, 2, 0, 0, -255,
                    0, 0, 2, 0, -255,
                    0, 0, 0, 1, 0,
                  ]),
                  child: const Text('High Contrast'),
                ),
                PopupMenuItem(
                  value: ColorFilter.matrix([
                    -1,  0,  0, 0, 255,
                     0, -1,  0, 0, 255,
                     0,  0, -1, 0, 255,
                     0,  0,  0, 1,   0,
                  ]),
                  child: const Text('Invert'),
                ),
              ],
              onSelected: _applyFilter,
              tooltip: 'Apply filter',
            ),
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: _addText,
              tooltip: 'Add text',
            ),
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _addPhoto,
              tooltip: 'Add photo',
            ),
            IconButton(
              icon: const Icon(Icons.crop),
              onPressed: _startCropping,
              tooltip: 'Crop image',
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _showAdjustmentsDialog,
              tooltip: 'Adjust Image',
            ),
            IconButton(
              icon: const Icon(Icons.layers_clear),
              onPressed: _removeBackground,
              tooltip: 'bg remover',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Processing...', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}