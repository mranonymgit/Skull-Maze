import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import '../class/wall.dart';
import '../class/goal.dart';
import '../class/main_game.dart';

// ================= Jugador Optimizado =================
class Player extends PositionComponent
    with HasGameRef<SkullMazeGame>, CollisionCallbacks {
  Player({
    required super.position,
    super.anchor = Anchor.center,
  });

  Vector2 _previousPosition = Vector2.zero();
  Vector2 _velocity = Vector2.zero();
  final double playerSpeed = 250.0;
  final double acceleration = 1200.0;
  final double deceleration = 1500.0;
  final double maxSpeed = 300.0;
  bool goalReached = false;

  static const Color playerColor = Color(0xFF18FFFF);
  late Paint _paint;
  late double _radius;

  int gridX = 0;
  int gridY = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _paint = Paint()..color = playerColor;
    _radius = size.x / 2;
    add(CircleHitbox()..radius = _radius);
    _previousPosition = position.clone();
  }

  void updateSizeAndPosition(double cellSize, Vector2 offset) {
    size = Vector2.all(cellSize * 0.4);
    _radius = size.x / 2;
    position = Vector2(
        gridX * cellSize + cellSize / 2 + offset.x,
        gridY * cellSize + cellSize / 2 + offset.y
    );
    _previousPosition = position.clone();
    removeAll(children.whereType<CircleHitbox>());
    add(CircleHitbox()..radius = _radius);
  }

  void updateGridPosition(double cellSize, Vector2 offset) {
    gridX = ((position.x - offset.x - cellSize / 2) / cellSize).round();
    gridY = ((position.y - offset.y - cellSize / 2) / cellSize).round();
  }

  void applyInput(Vector2 input, double dt) {
    if (input.length > 0.1) {
      _velocity += input * acceleration * dt;
      if (_velocity.length > maxSpeed) {
        _velocity = _velocity.normalized() * maxSpeed;
      }
    } else {
      double currentSpeed = _velocity.length;
      if (currentSpeed > 0) {
        double newSpeed = max(0, currentSpeed - deceleration * dt);
        _velocity = _velocity.normalized() * newSpeed;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_velocity.length > 0.01) {
      _previousPosition = position.clone();
      Vector2 newPosition = position + _velocity * dt;

      bool canMove = true;
      for (var wall in gameRef.walls) {
        if (_willCollide(newPosition, wall)) {
          canMove = false;

          Vector2 correction = _resolveCollision(newPosition, wall);
          newPosition = correction;
          _velocity *= 0.5;
          break;
        }
      }

      position = newPosition;

      double mazeWidth = gameRef.effectiveGridSize * gameRef.cellSize;
      double mazeHeight = gameRef.effectiveGridSize * gameRef.cellSize;

      double minX = gameRef.mazeOffset.x + size.x / 2;
      double maxX = gameRef.mazeOffset.x + mazeWidth - size.x / 2;
      double minY = gameRef.mazeOffset.y + size.y / 2;
      double maxY = gameRef.mazeOffset.y + mazeHeight - size.y / 2;

      if (position.x < minX || position.x > maxX) {
        position.x = position.x.clamp(minX, maxX);
        _velocity.x = 0;
      }
      if (position.y < minY || position.y > maxY) {
        position.y = position.y.clamp(minY, maxY);
        _velocity.y = 0;
      }

      updateGridPosition(gameRef.cellSize, gameRef.mazeOffset);
    }
  }

  Vector2 _resolveCollision(Vector2 newPosition, Wall wall) {
    double reducedSize = wall.size.x * wall.wallThicknessRatio;
    double offset = (wall.size.x - reducedSize) / 2;
    double wallLeft = wall.position.x + offset;
    double wallRight = wallLeft + reducedSize;
    double wallTop = wall.position.y + offset;
    double wallBottom = wallTop + reducedSize;

    double playerRadius = size.x / 2;

    double closestX = newPosition.x.clamp(wallLeft, wallRight);
    double closestY = newPosition.y.clamp(wallTop, wallBottom);

    double dx = newPosition.x - closestX;
    double dy = newPosition.y - closestY;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance < playerRadius) {
      double overlap = playerRadius - distance;
      if (distance > 0) {
        double normalX = dx / distance;
        double normalY = dy / distance;
        return Vector2(
          newPosition.x + normalX * overlap,
          newPosition.y + normalY * overlap,
        );
      } else {
        return _previousPosition;
      }
    }
    return newPosition;
  }

  bool _willCollide(Vector2 newPosition, Wall wall) {
    double reducedSize = wall.size.x * wall.wallThicknessRatio;
    double offset = (wall.size.x - reducedSize) / 2;
    double wallLeft = wall.position.x + offset;
    double wallRight = wallLeft + reducedSize;
    double wallTop = wall.position.y + offset;
    double wallBottom = wallTop + reducedSize;

    double playerRadius = size.x / 2;

    double closestX = newPosition.x.clamp(wallLeft, wallRight);
    double closestY = newPosition.y.clamp(wallTop, wallBottom);

    double dx = newPosition.x - closestX;
    double dy = newPosition.y - closestY;
    double distanceSquared = dx * dx + dy * dy;

    return distanceSquared < (playerRadius * playerRadius);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Goal) {
      print('¡Meta alcanzada en el nivel ${gameRef.level}!');
      goalReached = true;
      gameRef.onGoalReached();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, _radius, _paint);
  }
}