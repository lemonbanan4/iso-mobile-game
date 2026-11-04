import 'audio_hooks_stub.dart'
    if (dart.library.html) 'audio_hooks_web.dart' as impl;

/// Modular UI / gameplay audio triggers (Web Audio beeps or silent stub).
class AudioHooks {
  AudioHooks._();

  static final AudioHooks instance = AudioHooks._();

  bool enabled = true;

  void uiClick() {
    if (!enabled) return;
    impl.playTone(frequencyHz: 520, durationMs: 45, gain: 0.04);
  }

  void buildPlace() {
    if (!enabled) return;
    impl.playTone(frequencyHz: 680, durationMs: 90, gain: 0.06);
    Future<void>.delayed(const Duration(milliseconds: 70), () {
      if (!enabled) return;
      impl.playTone(frequencyHz: 880, durationMs: 70, gain: 0.05);
    });
  }

  void alertSiren() {
    if (!enabled) return;
    impl.playTone(frequencyHz: 240, durationMs: 160, gain: 0.07);
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (!enabled) return;
      impl.playTone(frequencyHz: 180, durationMs: 180, gain: 0.07);
    });
  }

  void gainChime() {
    if (!enabled) return;
    impl.playTone(frequencyHz: 740, durationMs: 55, gain: 0.035);
  }

  void rivalPing() {
    if (!enabled) return;
    impl.playTone(frequencyHz: 360, durationMs: 80, gain: 0.05);
  }
}
