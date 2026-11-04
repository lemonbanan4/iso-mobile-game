import 'dart:js_interop';

/// Web Audio oscillator beeps via JS eval (no SFX asset pack required).
void playTone({
  required double frequencyHz,
  required int durationMs,
  double gain = 0.05,
}) {
  try {
    final js = '''
      (function(){
        try {
          var AC = window.AudioContext || window.webkitAudioContext;
          if (!AC) return;
          var ctx = new AC();
          var osc = ctx.createOscillator();
          var g = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.value = $frequencyHz;
          g.gain.value = $gain;
          osc.connect(g);
          g.connect(ctx.destination);
          osc.start();
          var t = ctx.currentTime + ($durationMs / 1000);
          g.gain.exponentialRampToValueAtTime(0.001, t);
          osc.stop(t);
        } catch (e) {}
      })();
    ''';
    _eval(js);
  } catch (_) {
    // Autoplay policies / missing AudioContext — fail silent.
  }
}

@JS('eval')
external void _eval(String code);
