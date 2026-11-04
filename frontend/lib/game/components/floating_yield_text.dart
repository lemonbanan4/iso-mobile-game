import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Floating +Credits / +Heat style popup above a district.
class FloatingYieldText extends PositionComponent {
  final String text;
  final Color color;
  double lifeTimer = 1.35;
  final double maxLife = 1.35;

  FloatingYieldText({
    required this.text,
    required this.color,
    required Vector2 position,
  }) : super(position: position, priority: 9999);

  @override
  void update(double dt) {
    super.update(dt);
    lifeTimer -= dt;
    position.y -= 42 * dt;
    if (lifeTimer <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = (lifeTimer / maxLife).clamp(0.0, 1.0);
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: opacity),
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: opacity * 0.85),
            blurRadius: 6,
            offset: const Offset(1, 2),
          ),
          Shadow(
            color: color.withValues(alpha: opacity * 0.45),
            blurRadius: 10,
          ),
        ],
      ),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2),
    );
  }
}
