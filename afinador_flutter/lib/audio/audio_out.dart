import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import '../core/wav.dart';

/// Saída de áudio: nota de referência (uma vez) e metrônomo (fluxo contínuo).
class AudioOut {
  bool _ready = false;
  int _counter = 0;
  AudioSource? _stream;
  SoundHandle? _streamHandle;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await SoLoud.instance.init(sampleRate: outputSampleRate, channels: Channels.mono);
    _ready = true;
  }

  Future<void> playOnce(Uint8List wav, Duration length) async {
    await _ensureReady();
    final source = await SoLoud.instance.loadMem('nota_${_counter++}.wav', wav);
    SoLoud.instance.play(source);
    Future<void>.delayed(length + const Duration(seconds: 1), () async {
      await SoLoud.instance.disposeSource(source);
    });
  }

  /// Abre um fluxo de áudio mono, já com [first] na fila, e começa a tocar.
  ///
  /// No modo `released` o áudio tocado é descartado, então o fluxo pode durar
  /// o tempo que for. Sem tempo mínimo de espera: se a fila esvaziar, sai
  /// silêncio e o fluxo continua.
  Future<void> startStream(Float32List first) async {
    await _ensureReady();
    await stopStream();
    final source = SoLoud.instance.setBufferStream(
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      sampleRate: outputSampleRate,
      channels: Channels.mono,
      format: BufferType.f32le,
    );
    _stream = source;
    pushSamples(first);
    _streamHandle = SoLoud.instance.play(source);
  }

  void pushSamples(Float32List samples) {
    final source = _stream;
    if (source == null) return;
    SoLoud.instance.addAudioDataStream(
      source,
      samples.buffer.asUint8List(samples.offsetInBytes, samples.lengthInBytes),
    );
  }

  /// Quantas amostras do fluxo já foram tocadas.
  int get playedSamples {
    final source = _stream;
    if (source == null) return 0;
    final played = SoLoud.instance.getStreamTimeConsumed(source);
    return (played.inMicroseconds * outputSampleRate / 1e6).round();
  }

  Future<void> stopStream() async {
    final handle = _streamHandle;
    final source = _stream;
    _streamHandle = null;
    _stream = null;
    if (handle != null) await SoLoud.instance.stop(handle);
    if (source != null) await SoLoud.instance.disposeSource(source);
  }
}
