
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';

// ================= Pared de Contorno Neón Optimizada =================
class NeonBorderWall extends PositionComponent with CollisionCallbacks {
  final double borderThickness;
  static const Color neonCyan = Color(0xFF00FFFF);

  late Paint _borderPaint;
  late Rect _rect;

  NeonBorderWall({
    required super.position,
    required super.size,
    this.borderThickness = 8.0,
    super.anchor = Anchor.topLeft,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _rect = size.toRect();
    _borderPaint = Paint()
      ..color = neonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness;

    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(_rect, _borderPaint);
  }
}