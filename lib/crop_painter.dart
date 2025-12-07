import 'dart:ui';
import 'package:flutter/material.dart';

class CropPainter extends CustomPainter {
  final Rect imageRect;
  final Rect cropRect;
  final Size imageSize;
  final int? corner;
  final Offset? dragPoint;

  CropPainter({
    required this.imageRect,
    required this.cropRect,
    required this.imageSize,
    this.corner,
    this.dragPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = imageRect.width / imageSize.width;
    final scaleY = imageRect.height / imageSize.height;
    
    final screenCropRect = Rect.fromLTWH(
      imageRect.left + cropRect.left * scaleX,
      imageRect.top + cropRect.top * scaleY,
      cropRect.width * scaleX,
      cropRect.height * scaleY,
    );

    final dimPaint = Paint()..color = Colors.black.withOpacity(0.6);
    
    canvas.drawRect(
      Rect.fromLTRB(
        imageRect.left,
        imageRect.top,
        imageRect.right,
        screenCropRect.top,
      ),
      dimPaint,
    );
    
    canvas.drawRect(
      Rect.fromLTRB(
        imageRect.left,
        screenCropRect.bottom,
        imageRect.right,
        imageRect.bottom,
      ),
      dimPaint,
    );
    
    canvas.drawRect(
      Rect.fromLTRB(
        imageRect.left,
        screenCropRect.top,
        screenCropRect.left,
        screenCropRect.bottom,
      ),
      dimPaint,
    );
    
    canvas.drawRect(
      Rect.fromLTRB(
        screenCropRect.right,
        screenCropRect.top,
        imageRect.right,
        screenCropRect.bottom,
      ),
      dimPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(screenCropRect, borderPaint);

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final handleSize = 20.0;
    final halfHandle = handleSize / 2;

    canvas.drawRect(
      Rect.fromLTWH(
        screenCropRect.left - halfHandle,
        screenCropRect.top - halfHandle,
        handleSize,
        handleSize,
      ),
      handlePaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        screenCropRect.right - halfHandle,
        screenCropRect.top - halfHandle,
        handleSize,
        handleSize,
      ),
      handlePaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        screenCropRect.left - halfHandle,
        screenCropRect.bottom - halfHandle,
        handleSize,
        handleSize,
      ),
      handlePaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        screenCropRect.right - halfHandle,
        screenCropRect.bottom - halfHandle,
        handleSize,
        handleSize,
      ),
      handlePaint,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final verticalThird = screenCropRect.width / 3;
    canvas.drawLine(
      Offset(screenCropRect.left + verticalThird, screenCropRect.top),
      Offset(screenCropRect.left + verticalThird, screenCropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(screenCropRect.left + verticalThird * 2, screenCropRect.top),
      Offset(screenCropRect.left + verticalThird * 2, screenCropRect.bottom),
      gridPaint,
    );

    final horizontalThird = screenCropRect.height / 3;
    canvas.drawLine(
      Offset(screenCropRect.left, screenCropRect.top + horizontalThird),
      Offset(screenCropRect.right, screenCropRect.top + horizontalThird),
      gridPaint,
    );
    canvas.drawLine(
      Offset(screenCropRect.left, screenCropRect.top + horizontalThird * 2),
      Offset(screenCropRect.right, screenCropRect.top + horizontalThird * 2),
      gridPaint,
    );

    if (corner != null && dragPoint != null) {
      final activeHandlePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      Offset handleCenter;
      switch (corner) {
        case 0:
          handleCenter = screenCropRect.topLeft;
          break;
        case 1:
          handleCenter = screenCropRect.topRight;
          break;
        case 2:
          handleCenter = screenCropRect.bottomLeft;
          break;
        case 3:
          handleCenter = screenCropRect.bottomRight;
          break;
        default:
          handleCenter = Offset.zero;
      }

      canvas.drawCircle(
        handleCenter,
        15.0,
        activeHandlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CropPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect ||
        oldDelegate.cropRect != cropRect ||
        oldDelegate.corner != corner ||
        oldDelegate.dragPoint != dragPoint;
  }
}