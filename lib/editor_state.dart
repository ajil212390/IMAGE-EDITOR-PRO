import 'dart:typed_data';
import 'package:ajilmon/resizable_image.dart';
import 'package:ajilmon/resizable_text.dart';
import 'package:flutter/material.dart';


class EditorState {
  final Uint8List imageBytes;
  final List<ResizableImage> imageWidgets;
  final List<ResizableText> textWidgets;
  final ColorFilter? filter;

  EditorState({
    required this.imageBytes,
    required this.imageWidgets,
    required this.textWidgets,
    this.filter,
  });
}