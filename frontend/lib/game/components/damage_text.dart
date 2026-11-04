import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DamageText extends PositionComponent {
  final String text;
  double lifeTimer = 1.5;
  final double maxLife = 1.5;

  DamageText({required this.text, required Vector2 position})
    : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    lifeTimer -= dt;

    // Float upwards at 35 pixels per second
    position.y -= 35 * dt;

    if (lifeTimer <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Calculate a fade-out curve (1.0  to 0.0)
    final opacity = (lifeTimer / maxLife).clamp(0.0, 1.0);

    final paintColor = const Color(0xFFFF5252).withValues(alpha: opacity);
    final shadowColor = Colors.black.withValues(alpha: opacity);

    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: paintColor,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(color: shadowColor, blurRadius: 4, offset: const Offset(2, 2)),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
