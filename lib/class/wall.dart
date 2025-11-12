import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';

// ================= Pared Optimizada =================
class Wall extends PositionComponent with CollisionCallbacks {
  final double wallThicknessRatio = 0.85;
  static const Color neonColor = Color(0xFF7C4DFF);
  static const Color borderColor = Color(0xFFB39DDB);

  late Paint _mainPaint;
  late Paint _borderPaint;
  late RRect _rect;
  late double _reducedSize;
  late double _offset;

  Wall({required super.position, required super.size, super.anchor = Anchor.topLeft});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _reducedSize = size.x * wallThicknessRatio;
    _offset = (size.x - _reducedSize) / 2;
    double cornerRadius = _reducedSize * 0.25;

    _rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_offset, _offset, _reducedSize, _reducedSize),
      Radius.circular(cornerRadius),
    );

    _mainPaint = Paint()..color = neonColor.withOpacity(0.85);
    _borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    add(RectangleHitbox(
      position: Vector2(_offset, _offset),
      size: Vector2.all(_reducedSize),
    ));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_rect, _mainPaint);
    canvas.drawRRect(_rect, _borderPaint);
  }
}