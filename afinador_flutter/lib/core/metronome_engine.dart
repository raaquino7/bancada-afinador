// Gerador do metrônomo em fluxo contínuo (sem Flutter).
//
// Em vez de repetir um compasso pré-gravado, o som é gerado em blocos curtos,
// com cada clique na posição exata de amostra. Mudar o andamento vale a
// partir do próximo clique, sem parar o som nem voltar ao início do compasso.
import 'dart:math' as math;
import 'dart:typed_data';

/// Um tempo marcado: em que amostra começa e qual é o tempo do compasso.
class BeatMark {
  const BeatMark(this.sample, this.beat);
  final int sample;
  final int beat;
}

enum _ClickKind { strong, beat, subdivision }

class _Voice {
  _Voice(this.wave, this.start);
  final Float32List wave;
  final int start;
}

class MetronomeEngine {
  MetronomeEngine({
    required this.sampleRate,
    this.bpm = 100,
    this._beats = 4,
    List<int> strongBeats = const [0],
    this._subdivision = 1,
  }) : _strong = List<int>.of(strongBeats) {
    _waves = {
      for (final kind in _ClickKind.values) kind: _clickWave(kind),
    };
  }

  final int sampleRate;
  late final Map<_ClickKind, Float32List> _waves;

  /// Andamento. Uma mudança vale a partir do próximo clique.
  int bpm;
  int _beats;
  List<int> _strong;
  int _subdivision;

  /// Quantas amostras já foram geradas.
  int get written => _written;
  int _written = 0;

  /// Posição exata (fracionária) do último clique; nula antes do primeiro.
  double? _lastStepAt;
  int _step = 0;
  final List<_Voice> _voices = [];

  /// Tempos já gerados, em ordem, para a tela acender a bolinha certa.
  final List<BeatMark> marks = [];

  /// Troca o compasso ou a subdivisão. O próximo clique é o primeiro tempo.
  void setMeter({required int beats, required List<int> strongBeats, required int subdivision}) {
    _beats = beats;
    _strong = List<int>.of(strongBeats);
    _subdivision = subdivision;
    _step = 0;
  }

  double get _stepSamples => sampleRate * 60.0 / bpm / _subdivision;

  /// Gera os próximos [frames] de áudio, entre -1 e 1.
  Float32List render(int frames) {
    final out = Float32List(frames);
    final start = _written;
    final end = start + frames;

    while (true) {
      final last = _lastStepAt;
      // Se o andamento acelerou e o clique "devido" já passou, toca agora.
      final next = last == null ? start.toDouble() : math.max(last + _stepSamples, start.toDouble());
      final at = next.round();
      if (at >= end) break;

      final total = _beats * _subdivision;
      final step = _step % total;
      final onBeat = step % _subdivision == 0;
      final beat = step ~/ _subdivision;
      final kind = onBeat
          ? (_strong.contains(beat) ? _ClickKind.strong : _ClickKind.beat)
          : _ClickKind.subdivision;
      _voices.add(_Voice(_waves[kind]!, at));
      if (onBeat) marks.add(BeatMark(at, beat));

      _lastStepAt = next;
      _step = (step + 1) % total;
    }

    for (final voice in _voices) {
      final from = math.max(voice.start, start);
      final to = math.min(voice.start + voice.wave.length, end);
      for (var i = from; i < to; i++) {
        out[i - start] += voice.wave[i - voice.start];
      }
    }
    _voices.removeWhere((v) => v.start + v.wave.length <= end);

    _written = end;
    return out;
  }

  /// Último tempo que já começou a tocar na amostra [played], ou nulo.
  /// Descarta as marcas mais antigas que ele.
  BeatMark? beatAt(int played) {
    var index = -1;
    for (var i = 0; i < marks.length; i++) {
      if (marks[i].sample <= played) {
        index = i;
      } else {
        break;
      }
    }
    if (index < 0) return null;
    final mark = marks[index];
    marks.removeRange(0, index);
    return mark;
  }

  /// Os mesmos cliques do protótipo: senoide curta com queda exponencial.
  Float32List _clickWave(_ClickKind kind) {
    final freq = switch (kind) {
      _ClickKind.strong => 1568.0,
      _ClickKind.beat => 1047.0,
      _ClickKind.subdivision => 784.0,
    };
    final amp = switch (kind) {
      _ClickKind.strong => 0.6,
      _ClickKind.beat => 0.4,
      _ClickKind.subdivision => 0.16,
    };
    final length = (0.05 * sampleRate).round();
    final decay = math.log(0.001) / 0.05;
    final wave = Float32List(length);
    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      wave[i] = amp * math.exp(decay * t) * math.sin(2 * math.pi * freq * t);
    }
    return wave;
  }
}
