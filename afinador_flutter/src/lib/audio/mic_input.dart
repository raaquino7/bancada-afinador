import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Capta o microfone em PCM e entrega janelas de 8192 amostras para análise,
/// uma nova a cada 2048 amostras (cerca de 21 vezes por segundo).
class MicInput {
  static const int sampleRate = 44100;
  static const int windowSize = 8192;
  static const int hopSize = 2048;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  final Float32List _window = Float32List(windowSize);
  final Float32List _pending = Float32List(hopSize);
  int _filled = 0;
  int _pendingCount = 0;
  int? _carry;

  void Function(Float32List window)? onWindow;

  /// Devolve false quando a permissão do microfone foi negada.
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
    _filled = 0;
    _pendingCount = 0;
    _carry = null;
    _subscription = stream.listen(_onChunk);
    return true;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _recorder.stop();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _recorder.dispose();
  }

  void _emit() {
    final callback = onWindow;
    if (callback != null) callback(_window);
  }

  void _push(double sample) {
    if (_filled < windowSize) {
      _window[_filled++] = sample;
      if (_filled == windowSize) _emit();
      return;
    }
    _pending[_pendingCount++] = sample;
    if (_pendingCount == hopSize) {
      _window.setRange(0, windowSize - hopSize, _window, hopSize);
      _window.setRange(windowSize - hopSize, windowSize, _pending);
      _pendingCount = 0;
      _emit();
    }
  }

  void _onChunk(Uint8List chunk) {
    var i = 0;
    // Um bloco pode terminar no meio de uma amostra de 16 bits.
    final carry = _carry;
    if (carry != null && chunk.isNotEmpty) {
      _push(_toSample(carry, chunk[0]));
      _carry = null;
      i = 1;
    }
    for (; i + 1 < chunk.length; i += 2) {
      _push(_toSample(chunk[i], chunk[i + 1]));
    }
    if (i < chunk.length) _carry = chunk[i];
  }

  double _toSample(int low, int high) {
    var v = (high << 8) | low;
    if (v >= 0x8000) v -= 0x10000;
    return v / 32768.0;
  }
}
