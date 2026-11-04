import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/game_theme.dart';

class ConstructionTimer extends StatefulWidget {
  final int readyAtTimestamp;

  const ConstructionTimer({super.key, required this.readyAtTimestamp});

  @override
  State<ConstructionTimer> createState() => _ConstructionTimerState();
}

class _ConstructionTimerState extends State<ConstructionTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = widget.readyAtTimestamp - now;

    setState(() {
      _timeLeft = remaining > 0 ? Duration(seconds: remaining) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.inSeconds <= 0) {
      return const Text(
        'Online & Operational',
        style: TextStyle(
          color: GameTheme.accentNeon,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    String formattedTime =
        '${_timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.handyman, color: Colors.orangeAccent, size: 14),
          const SizedBox(width: 6),
          Text(
            'Under Construction: $formattedTime',
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
