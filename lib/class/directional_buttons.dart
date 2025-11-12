import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'dart:async' as async;

// ================= Control Buttons Widget =================
class DirectionalButtons extends StatefulWidget {
  final Function(Vector2) onDirectionChange;
  final bool isLandscape;

  const DirectionalButtons({
    super.key,
    required this.onDirectionChange,
    required this.isLandscape,
  });

  @override
  State<DirectionalButtons> createState() => _DirectionalButtonsState();
}

class _DirectionalButtonsState extends State<DirectionalButtons> {
  final Set<String> _pressedButtons = {};
  async.Timer? _updateTimer;

  void _updateDirection() {
    Vector2 direction = Vector2.zero();

    if (_pressedButtons.contains('up')) direction.y -= 1;
    if (_pressedButtons.contains('down')) direction.y += 1;
    if (_pressedButtons.contains('left')) direction.x -= 1;
    if (_pressedButtons.contains('right')) direction.x += 1;

    widget.onDirectionChange(direction.length > 0 ? direction.normalized() : Vector2.zero());
  }

  void _startContinuousUpdate(String direction) {
    setState(() => _pressedButtons.add(direction));
    _updateDirection();

    _updateTimer?.cancel();
    _updateTimer = async.Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_pressedButtons.contains(direction)) {
        _updateDirection();
      }
    });
  }

  void _stopContinuousUpdate(String direction) {
    setState(() => _pressedButtons.remove(direction));
    _updateDirection();

    if (_pressedButtons.isEmpty) {
      _updateTimer?.cancel();
      _updateTimer = null;
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Widget _buildButton({
    required IconData icon,
    required String direction,
    required double size,
  }) {
    final isPressed = _pressedButtons.contains(direction);

    return Listener(
      onPointerDown: (_) {
        HapticFeedback.lightImpact();
        _startContinuousUpdate(direction);
      },
      onPointerUp: (_) {
        _stopContinuousUpdate(direction);
      },
      onPointerCancel: (_) {
        _stopContinuousUpdate(direction);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPressed
              ? const Color(0xFF7CFC00).withOpacity(0.6)
              : const Color(0xFF424242).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF7CFC00),
            width: 2,
          ),
          boxShadow: isPressed ? [
            BoxShadow(
              color: const Color(0xFF7CFC00).withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ] : [],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final minDimension = min(screenSize.width, screenSize.height);
    final buttonSize = minDimension * 0.12;
    final spacing = minDimension * 0.02;

    if (widget.isLandscape) {
      return Padding(
        padding: EdgeInsets.all(minDimension * 0.03),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              icon: Icons.arrow_upward,
              direction: 'up',
              size: buttonSize,
            ),
            SizedBox(height: spacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildButton(
                  icon: Icons.arrow_back,
                  direction: 'left',
                  size: buttonSize,
                ),
                SizedBox(width: spacing),
                _buildButton(
                  icon: Icons.arrow_downward,
                  direction: 'down',
                  size: buttonSize,
                ),
                SizedBox(width: spacing),
                _buildButton(
                  icon: Icons.arrow_forward,
                  direction: 'right',
                  size: buttonSize,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.all(minDimension * 0.03),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              icon: Icons.arrow_upward,
              direction: 'up',
              size: buttonSize,
            ),
            SizedBox(height: spacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildButton(
                  icon: Icons.arrow_back,
                  direction: 'left',
                  size: buttonSize,
                ),
                SizedBox(width: buttonSize + spacing * 2),
                _buildButton(
                  icon: Icons.arrow_forward,
                  direction: 'right',
                  size: buttonSize,
                ),
              ],
            ),
            SizedBox(height: spacing),
            _buildButton(
              icon: Icons.arrow_downward,
              direction: 'down',
              size: buttonSize,
            ),
          ],
        ),
      );
    }
  }
}