import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

class ResizableText extends StatefulWidget {
  final String text;
  final Color color;
  final String fontFamily;
  final VoidCallback onDelete;

  const ResizableText({
    required this.text,
    required this.color,
    required this.fontFamily,
    required this.onDelete,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ResizableTextState createState() => _ResizableTextState();
}

class _ResizableTextState extends State<ResizableText> {
  double x = 100;
  double y = 100;
  double textWidth = 150;
  double textHeight = 50;
  double fontSize = 20;
  double rotationAngle = 0.0;
  bool isSelected = false;
  bool hasShadow = false;
  double shadowIntensity = 5.0;
  Color shadowColor = Colors.black;
  TextAlign textAlign = TextAlign.center; // Set initial text alignment to center
  bool hasEmboss = false;
  Color embossHighlightColor = Colors.white;
  Color embossShadowColor = Colors.black;
  double embossDepth = 2.0;
  
  // Gradient properties
  bool hasGradient = false;
  Color gradientStartColor = Colors.blue;
  Color gradientEndColor = Colors.purple;
  Alignment gradientBegin = Alignment.centerLeft;
  Alignment gradientEnd = Alignment.centerRight;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x.clamp(0, MediaQuery.of(context).size.width - textWidth),
      top: y.clamp(0, MediaQuery.of(context).size.height - textHeight),
      child: GestureDetector(
        onTap: () => setState(() => isSelected = !isSelected),
        onLongPress: () => showDeleteDialog(),
        onPanUpdate: (details) => setState(() {
          x += details.delta.dx;
          y += details.delta.dy;
        }),
        child: Transform.rotate(
          angle: rotationAngle,
          child: Stack(
            children: [
              Container(
                width: textWidth,
                height: textHeight,
                decoration: isSelected
                    ? BoxDecoration(border: Border.all(color: Colors.blue))
                    : null,
                child: buildStyledText(),
              ),
              if (isSelected) ...[
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: resizeHandler,
                    child: const Icon(Icons.zoom_out_map, color: Colors.blue, size: 20),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onPanUpdate: rotateHandler,
                    child: const Icon(Icons.rotate_right, color: Colors.green, size: 20),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.purple),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'shadow',
                        child: Text('Shadow Settings'),
                      ),
                      const PopupMenuItem(
                        value: 'alignment',
                        child: Text('Text Alignment'),
                      ),
                      const PopupMenuItem(
                        value: 'emboss',
                        child: Text('Emboss Effect'),
                      ),
                      const PopupMenuItem(
                        value: 'gradient',
                        child: Text('Gradient Text'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'shadow') {
                        showShadowDialog();
                      } else if (value == 'alignment') {
                        showAlignmentDialog();
                      } else if (value == 'emboss') {
                        showEmbossDialog();
                      } else if (value == 'gradient') {
                        showGradientDialog();
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStyledText() {
    List<Shadow> shadows = [];

    if (hasShadow) {
      shadows.add(Shadow(
        // ignore: deprecated_member_use
        color: shadowColor.withOpacity(shadowIntensity / 10),
        blurRadius: shadowIntensity,
        offset: const Offset(2, 2),
      ));
    }

    if (hasEmboss) {
      shadows.addAll([
        Shadow(
          color: embossHighlightColor,
          offset: Offset(-embossDepth, -embossDepth),
        ),
        Shadow(
          color: embossShadowColor,
          offset: Offset(embossDepth, embossDepth),
        ),
      ]);
    }

    // Create base text style - use widget.color as the base color for all cases
    TextStyle textStyle = GoogleFonts.getFont(
      widget.fontFamily,
      fontSize: fontSize,
      color: widget.color, // Always use the widget's color as the base
      fontWeight: FontWeight.bold,
      shadows: shadows,
    );

    // If gradient is applied, wrap text in ShaderMask
    // This preserves the shadows from the emboss effect
    if (hasGradient) {
      return ShaderMask(
        blendMode: BlendMode.srcIn, // Only affects the text color, not the shadows
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: gradientBegin,
            end: gradientEnd,
            colors: [gradientStartColor, gradientEndColor],
          ).createShader(bounds);
        },
        child: Text(
          widget.text,
          textAlign: textAlign,
          style: textStyle,
        ),
      );
    } else {
      // Standard text without gradient
      return Text(
        widget.text,
        textAlign: textAlign,
        style: textStyle,
      );
    }
  }

  void showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Text?'),
        content: const Text('Are you sure you want to delete this text?'),
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
      textWidth += details.delta.dx;
      textHeight += details.delta.dy;
      fontSize = (textHeight / 2).clamp(10, 500);
    });
  }

  void rotateHandler(DragUpdateDetails details) {
    setState(() => rotationAngle += details.delta.dx * 0.01);
  }

  void showShadowDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Text Shadow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Shadow Color'),
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: MaterialPicker(
                    pickerColor: shadowColor,
                    onColorChanged: (color) => setStateDialog(() => shadowColor = color),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Shadow Intensity'),
                Slider(
                  value: shadowIntensity,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  onChanged: (value) => setStateDialog(() => shadowIntensity = value),
                  label: shadowIntensity.toStringAsFixed(1),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          hasShadow = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Remove Shadow'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          hasShadow = true;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showAlignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  const Text('Text Alignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Left'),
                contentPadding: EdgeInsets.zero,
                leading: Radio<TextAlign>(
                  value: TextAlign.left,
                  groupValue: textAlign,
                  onChanged: (value) {
                    setState(() => textAlign = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Center'),
                contentPadding: EdgeInsets.zero,
                leading: Radio<TextAlign>(
                  value: TextAlign.center,
                  groupValue: textAlign,
                  onChanged: (value) {
                    setState(() => textAlign = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Right'),
                contentPadding: EdgeInsets.zero,
                leading: Radio<TextAlign>(
                  value: TextAlign.right,
                  groupValue: textAlign,
                  onChanged: (value) {
                    setState(() => textAlign = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showEmbossDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Emboss Effect', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Highlight', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: MaterialPicker(
                    pickerColor: embossHighlightColor,
                    onColorChanged: (color) => setStateDialog(() => embossHighlightColor = color),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Shadow', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: MaterialPicker(
                    pickerColor: embossShadowColor,
                    onColorChanged: (color) => setStateDialog(() => embossShadowColor = color),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Emboss Depth', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: embossDepth,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  onChanged: (value) => setStateDialog(() => embossDepth = value),
                  label: embossDepth.toStringAsFixed(1),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          hasEmboss = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Remove Emboss'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          hasEmboss = true;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void showGradientDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gradient Text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Start Color', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: MaterialPicker(
                      pickerColor: gradientStartColor,
                      onColorChanged: (color) => setStateDialog(() => gradientStartColor = color),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('End Color', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: MaterialPicker(
                      pickerColor: gradientEndColor,
                      onColorChanged: (color) => setStateDialog(() => gradientEndColor = color),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Gradient Direction', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _directionButton(
                        setStateDialog,
                        Icons.format_align_left,
                        'Horizontal',
                        gradientBegin == Alignment.centerLeft && gradientEnd == Alignment.centerRight,
                        () {
                          setStateDialog(() {
                            gradientBegin = Alignment.centerLeft;
                            gradientEnd = Alignment.centerRight;
                          });
                        },
                      ),
                      _directionButton(
                        setStateDialog,
                        Icons.vertical_align_top,
                        'Vertical',
                        gradientBegin == Alignment.topCenter && gradientEnd == Alignment.bottomCenter,
                        () {
                          setStateDialog(() {
                            gradientBegin = Alignment.topCenter;
                            gradientEnd = Alignment.bottomCenter;
                          });
                        },
                      ),
                      _directionButton(
                        setStateDialog,
                        Icons.north_west,
                        'Diagonal',
                        gradientBegin == Alignment.topLeft && gradientEnd == Alignment.bottomRight,
                        () {
                          setStateDialog(() {
                            gradientBegin = Alignment.topLeft;
                            gradientEnd = Alignment.bottomRight;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            hasGradient = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Remove Gradient'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            hasGradient = true;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _directionButton(
    StateSetter setState,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          // ignore: deprecated_member_use
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}