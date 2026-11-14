// Núcleo puro (sem Flutter): notas, conversões e detecção de altura (YIN).
// Portado linha a linha do protótipo web, onde foi validado com sinais sintéticos.
import 'dart:math' as math;
import 'dart:typed_data';

const List<String> noteNames = [
  'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B',
];
const List<String> solfegeNames = [
  'Dó', 'Dó♯', 'Ré', 'Ré♯', 'Mi', 'Fá', 'Fá♯', 'Sol', 'Sol♯', 'Lá', 'Lá♯', 'Si',
];
const Map<String, String> _solfegeByLetter = {
  'C': 'Dó', 'D': 'Ré', 'E': 'Mi', 'F': 'Fá', 'G': 'Sol', 'A': 'Lá', 'B': 'Si',
};
const Map<String, int> _semitoneByLetter = {
  'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11,
};

class Note {
  const Note(this.midi, this.label, this.octave, this.solfege);

  final int midi;
  final String label;
  final int octave;
  final String solfege;

  /// "Eb2", "F#3", "A4".
  factory Note.parse(String s) {
    final m = RegExp(r'^([A-G])([#b]?)(-?\d)$').firstMatch(s);
    if (m == null) {
      throw FormatException('Nota inválida: $s');
    }
    final letter = m.group(1)!;
    final accidental = m.group(2)!;
    final octave = int.parse(m.group(3)!);
    final acc = accidental == '#' ? 1 : (accidental == 'b' ? -1 : 0);
    final sign = acc == 1 ? '♯' : (acc == -1 ? '♭' : '');
    return Note(
      (octave + 1) * 12 + _semitoneByLetter[letter]! + acc,
      '$letter$sign',
      octave,
      '${_solfegeByLetter[letter]!}$sign',
    );
  }

  factory Note.fromMidi(int midi) {
    final pc = ((midi % 12) + 12) % 12;
    return Note(midi, noteNames[pc], (midi ~/ 12) - 1, solfegeNames[pc]);
  }
}

double midiToFreq(num midi, double a4) {
  return a4 * math.pow(2.0, (midi - 69) / 12.0).toDouble();
}

double freqToMidi(double freq, double a4) {
  return 69.0 + 12.0 * (math.log(freq / a4) / math.ln2);
}

/// Média de pares: reduz a taxa de amostragem pela metade com um filtro simples.
Float32List decimate2(Float32List buf) {
  final out = Float32List(buf.length >> 1);
  for (var i = 0; i < out.length; i++) {
    out[i] = 0.5 * (buf[2 * i] + buf[2 * i + 1]);
  }
  return out;
}

class PitchResult {
  const PitchResult(this.freq, this.clarity);
  final double freq;
  final double clarity;
}

/// Algoritmo YIN. Devolve null quando não há nota clara.
PitchResult? detectPitch(
  Float32List buf,
  double sampleRate, {
  double minFreq = 27,
  double maxFreq = 1400,
}) {
  final n = buf.length;
  var sum = 0.0;
  for (var i = 0; i < n; i++) {
    sum += buf[i] * buf[i];
  }
  if (math.sqrt(sum / n) < 0.006) return null;

  final tauMax = math.min((sampleRate / minFreq).floor(), n ~/ 2);
  final tauMin = math.max(2, (sampleRate / maxFreq).floor());
  final w = n - tauMax;
  final cmnd = Float64List(tauMax + 1);
  cmnd[0] = 1.0;
  var running = 0.0;
  for (var tau = 1; tau <= tauMax; tau++) {
    var d = 0.0;
    for (var i = 0; i < w; i++) {
      final diff = buf[i] - buf[i + tau];
      d += diff * diff;
    }
    running += d;
    cmnd[tau] = running > 0 ? d * tau / running : 1.0;
  }

  var best = -1;
  for (var tau = tauMin; tau < tauMax; tau++) {
    if (cmnd[tau] < 0.12) {
      var t = tau;
      while (t + 1 < tauMax && cmnd[t + 1] < cmnd[t]) {
        t++;
      }
      best = t;
      break;
    }
  }
  if (best < 0) {
    var minValue = 1.0;
    for (var tau = tauMin; tau < tauMax; tau++) {
      if (cmnd[tau] < minValue) {
        minValue = cmnd[tau];
        best = tau;
      }
    }
    if (best < 0 || minValue > 0.3) return null;
  }

  // Interpolação parabólica para precisão abaixo de uma amostra.
  var refined = best.toDouble();
  if (best > 1 && best < tauMax) {
    final a = cmnd[best - 1];
    final b = cmnd[best];
    final c = cmnd[best + 1];
    final den = a - 2 * b + c;
    if (den != 0) refined = best + 0.5 * (a - c) / den;
  }
  return PitchResult(sampleRate / refined, 1.0 - cmnd[best]);
}
