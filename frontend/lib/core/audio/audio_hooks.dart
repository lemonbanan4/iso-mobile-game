import 'audio_hooks_stub.dart'
    if (dart.library.html) 'audio_hooks_web.dart' as impl;

/// Modular UI / gameplay audio triggers (Web Audio synthesis).
class AudioHooks {
  AudioHooks._();

  static final AudioHooks instance = AudioHooks._();

  bool enabled = true;

  void uiClick() {
    if (!enabled) return;
    impl.playTone(
      frequencyHz: 640,
      durationMs: 40,
      gain: 0.035,
      wave: 'triangle',
    );
  }

  void buildPlace() {
    if (!enabled) return;
    impl.playNoiseBurst(durationMs: 55, gain: 0.03);
    impl.playTone(
      frequencyHz: 220,
      durationMs: 90,
      gain: 0.05,
      wave: 'square',
    );
    Future<void>.delayed(const Duration(milliseconds: 70), () {
      if (!enabled) return;
      impl.playTone(
        frequencyHz: 880,
        durationMs: 110,
        gain: 0.045,
        wave: 'sawtooth',
      );
    });
  }

  void alertSiren() {
    if (!enabled) return;
    impl.playTone(
      frequencyHz: 310,
      durationMs: 180,
      gain: 0.06,
      wave: 'sawtooth',
    );
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!enabled) return;
      impl.playTone(
        frequencyHz: 190,
        durationMs: 220,
        gain: 0.055,
        wave: 'square',
      );
    });
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!enabled) return;
      impl.playNoiseBurst(durationMs: 90, gain: 0.035);
    });
  }

  void gainChime() {
    if (!enabled) return;
    impl.playTone(
      frequencyHz: 740,
      durationMs: 60,
      gain: 0.03,
      wave: 'sine',
    );
    Future<void>.delayed(const Duration(milliseconds: 45), () {
      if (!enabled) return;
      impl.playTone(
        frequencyHz: 980,
        durationMs: 70,
        gain: 0.028,
        wave: 'triangle',
      );
    });
  }

  void rivalPing() {
    if (!enabled) return;
    impl.playTone(
      frequencyHz: 280,
      durationMs: 70,
      gain: 0.045,
      wave: 'square',
    );
    impl.playNoiseBurst(durationMs: 40, gain: 0.025);
  }

  void recruitConfirm() {
    if (!enabled) return;
    impl.playTone(
      frequencyHz: 520,
      durationMs: 80,
      gain: 0.04,
      wave: 'triangle',
    );
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (!enabled) return;
      impl.playTone(
        frequencyHz: 780,
        durationMs: 120,
        gain: 0.04,
        wave: 'sine',
      );
    });
  }

  void techUnlock() {
    if (!enabled) return;
    impl.playTone(
      frequencyHz: 420,
      durationMs: 70,
      gain: 0.04,
      wave: 'sawtooth',
    );
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!enabled) return;
      impl.playTone(
        frequencyHz: 840,
        durationMs: 140,
        gain: 0.045,
        wave: 'triangle',
      );
    });
  }
}
