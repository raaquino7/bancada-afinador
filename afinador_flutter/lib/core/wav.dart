// Síntese dos sons do app (nota de referência e compasso do metrônomo) em WAV.
import 'dart:math' as math;
import 'dart:typed_data';

/// 48 kHz, a taxa nativa dos celulares: o som não passa por conversão.
const int outputSampleRate = 48000;

/// WAV mono de 16 bits a partir de amostras entre -1 e 1.
Uint8List wavFromSamples(Float32List samples, {int sampleRate = outputSampleRate}) {
  final dataBytes = samples.length * 2;
  final bd = ByteData(44 + dataBytes);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      bd.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bd.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, 1, Endian.little); // mono
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bd.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = samples[i].clamp(-1.0, 1.0);
    bd.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return bd.buffer.asUint8List();
}

/// Nota de referência. Os harmônicos deixam as notas graves do baixo
/// audíveis no alto-falante do celular.
Float32List toneSamples(double freq, {double seconds = 2.4, int sampleRate = outputSampleRate}) {
  const amps = [1.0, 0.55, 0.38, 0.22, 0.12, 0.07];
  final n = (seconds * sampleRate).round();
  final out = Float32List(n);
  final decay = math.log(0.001) / seconds;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    var v = 0.0;
    for (var h = 0; h < amps.length; h++) {
      v += amps[h] * math.sin(2 * math.pi * freq * (h + 1) * t);
    }
    final attack = t < 0.02 ? t / 0.02 : 1.0;
    out[i] = 0.28 * attack * math.exp(decay * t) * v;
  }
  return out;
}

/// Um compasso inteiro do metrônomo, com os cliques em posições exatas de amostra.
/// Tocado em laço, o andamento não oscila.
Float32List metronomeBar({
  required int bpm,
  required int beats,
  required List<int> strongBeats,
  required int subdivision,
  int sampleRate = outputSampleRate,
}) {
  final steps = beats * subdivision;
  final stepSamples = sampleRate * 60.0 / bpm / subdivision;
  final total = (steps * stepSamples).round();
  final out = Float32List(total);
  final clickLen = (0.05 * sampleRate).round();
  final decay = math.log(0.001) / 0.05;
  for (var s = 0; s < steps; s++) {
    final onBeat = s % subdivision == 0;
    final strong = onBeat && strongBeats.contains(s ~/ subdivision);
    final freq = strong ? 1568.0 : (onBeat ? 1047.0 : 784.0);
    final amp = strong ? 0.6 : (onBeat ? 0.4 : 0.16);
    final start = (s * stepSamples).round();
    for (var i = 0; i < clickLen && start + i < total; i++) {
      final t = i / sampleRate;
      out[start + i] += amp * math.exp(decay * t) * math.sin(2 * math.pi * freq * t);
    }
  }
  return out;
}
