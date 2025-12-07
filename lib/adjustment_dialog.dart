import 'package:flutter/material.dart';
import 'image_editor_utils.dart';

class AdjustmentDialog extends StatefulWidget {
  final double initialBrightness;
  final double initialContrast;
  final double initialSaturation;
  final double initialHue;
  final double initialWhiteBalance;
  final double initialVignette;
  final double initialSharpness;
  final double initialTint;
  final double initialShadows;
  final double initialHighlights;
  final Function(ColorFilter) onAdjustmentsChanged;
  final VoidCallback onReset;

  const AdjustmentDialog({
    super.key,
    required this.initialBrightness,
    required this.initialContrast,
    required this.initialSaturation,
    required this.initialHue,
    required this.initialWhiteBalance,
    required this.initialVignette,
    required this.initialSharpness,
    required this.initialTint,
    required this.initialShadows,
    required this.initialHighlights,
    required this.onAdjustmentsChanged,
    required this.onReset,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AdjustmentDialogState createState() => _AdjustmentDialogState();
}

class _AdjustmentDialogState extends State<AdjustmentDialog> {
  late double brightness;
  late double contrast;
  late double saturation;
  late double hue;
  late double whiteBalance;
  late double vignette;
  late double sharpness;
  late double tint;
  late double shadows;
  late double highlights;

  @override
  void initState() {
    super.initState();
    brightness = widget.initialBrightness;
    contrast = widget.initialContrast;
    saturation = widget.initialSaturation;
    hue = widget.initialHue;
    whiteBalance = widget.initialWhiteBalance;
    vignette = widget.initialVignette;
    sharpness = widget.initialSharpness;
    tint = widget.initialTint;
    shadows = widget.initialShadows;
    highlights = widget.initialHighlights;
  }

  void _updateMatrix() {
    final matrix = ImageEditorUtils.createColorMatrix(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      hue: hue,
      whiteBalance: whiteBalance,
      vignette: vignette,
      sharpness: sharpness,
      tint: tint,
      shadows: shadows,
      highlights: highlights,
    );
    widget.onAdjustmentsChanged(ColorFilter.matrix(matrix));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Image'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSlider('Brightness', brightness, -1.0, 1.0, (value) {
              setState(() => brightness = value);
              _updateMatrix();
            }),
            _buildSlider('Contrast', contrast, 0.0, 2.0, (value) {
              setState(() => contrast = value);
              _updateMatrix();
            }),
            _buildSlider('Saturation', saturation, 0.0, 2.0, (value) {
              setState(() => saturation = value);
              _updateMatrix();
            }),
            _buildSlider('Hue', hue, -1.0, 1.0, (value) {
              setState(() => hue = value);
              _updateMatrix();
            }),
            _buildSlider('White Balance', whiteBalance, -1.0, 1.0, (value) {
              setState(() => whiteBalance = value);
              _updateMatrix();
            }),
            _buildSlider('Vignette', vignette, 0.0, 1.0, (value) {
              setState(() => vignette = value);
              _updateMatrix();
            }),
            _buildSlider('Sharpness', sharpness, -1.0, 1.0, (value) {
              setState(() => sharpness = value);
              _updateMatrix();
            }),
            _buildSlider('Tint', tint, -1.0, 1.0, (value) {
              setState(() => tint = value);
              _updateMatrix();
            }),
            _buildSlider('Shadows', shadows, -1.0, 1.0, (value) {
              setState(() => shadows = value);
              _updateMatrix();
            }),
            _buildSlider('Highlights', highlights, -1.0, 1.0, (value) {
              setState(() => highlights = value);
              _updateMatrix();
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onReset();
            Navigator.pop(context);
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}