import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';

// ================= Meta Optimizada =================
class Goal extends PositionComponent with CollisionCallbacks {
  static const Color goalColor = Color(0xFF3D5AFE);
  late Paint _paint;
  late double _radius;

  Goal({
    required super.position,
    super.anchor = Anchor.center,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _paint = Paint()..color = goalColor;
    _radius = size.x / 2;
    add(RectangleHitbox());
  }

  void updateSizeAndPosition(double cellSize, int gridX, int gridY, Vector2 offset) {
    size = Vector2.all(cellSize * 0.6);
    _radius = size.x / 2;
    position = Vector2(
        gridX * cellSize + cellSize / 2 + offset.x,
        gridY * cellSize + cellSize / 2 + offset.y
    );
    removeAll(children.whereType<RectangleHitbox>());
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, _radius, _paint);
  }
}