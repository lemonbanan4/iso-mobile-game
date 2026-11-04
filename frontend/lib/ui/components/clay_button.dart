import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../../core/theme/game_theme.dart';

/// 3D Claymorphic tactile button with depressed state on press.
class ClayButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color baseColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isAccent;

  const ClayButton({
    super.key,
    required this.child,
    this.onPressed,
    this.baseColor = GameTheme.claySurface,
    this.borderRadius = GameConstants.clayBorderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.isAccent = false,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double depthOffset = _isPressed ? 1.0 : 4.0;
    final double blur = _isPressed ? 4.0 : 12.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.isAccent
              ? GameTheme.accentNeonGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.baseColor.withValues(alpha: 0.9),
                    widget.baseColor.withValues(alpha: 0.65),
                  ],
                ),
          border: Border.all(
            color: widget.isAccent
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            // Dark ambient drop shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: Offset(depthOffset, depthOffset + 2),
              blurRadius: blur,
            ),
            // Light top-left rim highlight
            BoxShadow(
              color: Colors.white.withValues(alpha: _isPressed ? 0.08 : 0.25),
              offset: Offset(-depthOffset * 0.7, -depthOffset * 0.7),
              blurRadius: blur * 0.5,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
