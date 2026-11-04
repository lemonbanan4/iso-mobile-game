/// No-op audio on non-web platforms (assets optional later).
void playTone({
  required double frequencyHz,
  required int durationMs,
  double gain = 0.05,
  String wave = 'sine',
}) {}

void playNoiseBurst({
  required int durationMs,
  double gain = 0.04,
}) {}
