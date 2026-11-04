import 'dart:js_interop';

/// Shared Web Audio context + cyberpunk oscillator / noise synthesis.
void playTone({
  required double frequencyHz,
  required int durationMs,
  double gain = 0.05,
  String wave = 'sine',
}) {
  try {
    final js = '''
      (function(){
        try {
          var AC = window.AudioContext || window.webkitAudioContext;
          if (!AC) return;
          if (!window.__isoAudioCtx) window.__isoAudioCtx = new AC();
          var ctx = window.__isoAudioCtx;
          if (ctx.state === 'suspended') ctx.resume();
          var osc = ctx.createOscillator();
          var g = ctx.createGain();
          var filter = ctx.createBiquadFilter();
          filter.type = 'lowpass';
          filter.frequency.value = Math.max(900, $frequencyHz * 2.2);
          osc.type = '$wave';
          osc.frequency.setValueAtTime($frequencyHz, ctx.currentTime);
          g.gain.setValueAtTime(0.0001, ctx.currentTime);
          g.gain.exponentialRampToValueAtTime($gain, ctx.currentTime + 0.012);
          var t = ctx.currentTime + ($durationMs / 1000);
          g.gain.exponentialRampToValueAtTime(0.0001, t);
          osc.connect(filter);
          filter.connect(g);
          g.connect(ctx.destination);
          osc.start();
          osc.stop(t + 0.02);
        } catch (e) {}
      })();
    ''';
    _eval(js);
  } catch (_) {}
}

void playNoiseBurst({
  required int durationMs,
  double gain = 0.04,
}) {
  try {
    final js = '''
      (function(){
        try {
          var AC = window.AudioContext || window.webkitAudioContext;
          if (!AC) return;
          if (!window.__isoAudioCtx) window.__isoAudioCtx = new AC();
          var ctx = window.__isoAudioCtx;
          if (ctx.state === 'suspended') ctx.resume();
          var seconds = Math.max(0.04, $durationMs / 1000);
          var buffer = ctx.createBuffer(1, Math.floor(ctx.sampleRate * seconds), ctx.sampleRate);
          var data = buffer.getChannelData(0);
          for (var i = 0; i < data.length; i++) {
            data[i] = (Math.random() * 2 - 1) * (1 - i / data.length);
          }
          var src = ctx.createBufferSource();
          src.buffer = buffer;
          var g = ctx.createGain();
          var filter = ctx.createBiquadFilter();
          filter.type = 'bandpass';
          filter.frequency.value = 1800;
          filter.Q.value = 0.7;
          g.gain.value = $gain;
          src.connect(filter);
          filter.connect(g);
          g.connect(ctx.destination);
          src.start();
        } catch (e) {}
      })();
    ''';
    _eval(js);
  } catch (_) {}
}

@JS('eval')
external void _eval(String code);
