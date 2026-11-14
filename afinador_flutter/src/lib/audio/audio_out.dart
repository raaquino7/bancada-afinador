import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Saída de áudio: nota de referência (uma vez) e compasso do metrônomo (em laço).
class AudioOut {
  bool _ready = false;
  int _counter = 0;
  dynamic _loopSource;
  dynamic _loopHandle;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await SoLoud.instance.init();
    _ready = true;
  }

  Future<void> playOnce(Uint8List wav, Duration length) async {
    await _ensureReady();
    final source = await SoLoud.instance.loadMem('nota_${_counter++}.wav', wav);
    await SoLoud.instance.play(source);
    Future<void>.delayed(length + const Duration(seconds: 1), () async {
      await SoLoud.instance.disposeSource(source);
    });
  }

  Future<void> startLoop(Uint8List wav) async {
    await _ensureReady();
    await stopLoop();
    final source = await SoLoud.instance.loadMem('compasso_${_counter++}.wav', wav);
    _loopSource = source;
    _loopHandle = await SoLoud.instance.play(source, looping: true);
  }

  Future<void> stopLoop() async {
    final handle = _loopHandle;
    final source = _loopSource;
    _loopHandle = null;
    _loopSource = null;
    if (handle != null) await SoLoud.instance.stop(handle);
    if (source != null) await SoLoud.instance.disposeSource(source);
  }
}
