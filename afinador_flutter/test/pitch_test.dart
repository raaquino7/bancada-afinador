import 'dart:math' as math;
import 'dart:typed_data';

import 'package:afinador/core/pitch.dart';
import 'package:afinador/core/tunings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Corda dedilhada sintética: harmônicos fortes, fundamental fraca e ruído.
Float32List synth(double f, int sampleRate, int n, math.Random random) {
  const amps = [0.4, 1.0, 0.7, 0.5, 0.3, 0.2];
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    var v = 0.0;
    for (var h = 0; h < amps.length; h++) {
      v += amps[h] * math.sin(2 * math.pi * f * (h + 1) * i / sampleRate + h);
    }
    out[i] = 0.15 * v + 0.02 * (random.nextDouble() * 2 - 1);
  }
  return out;
}

void main() {
  test('detecta todas as notas de todas as afinações com erro de até 3 cents', () {
    final random = math.Random(1);
    for (final sampleRate in [44100, 48000]) {
      final seen = <int>{};
      for (final instrument in instruments) {
        for (final tuning in instrument.tunings) {
          for (final note in tuning.notes) {
            if (!seen.add(note.midi)) continue;
            for (final offset in [-0.3, 0.0, 0.17]) {
              final f = midiToFreq(note.midi + offset, 440);
              final buf = decimate2(synth(f, sampleRate, 8192, random));
              final hit = detectPitch(buf, sampleRate / 2);
              expect(hit, isNotNull, reason: '${note.label}${note.octave} não detectada');
              final cents = 1200 * math.log(hit!.freq / f) / math.ln2;
              expect(cents.abs(), lessThan(3), reason: '${note.label}${note.octave} em $sampleRate Hz');
            }
          }
        }
      }
    }
  });

  test('silêncio e ruído não viram nota', () {
    expect(detectPitch(Float32List(4096), 22050), isNull);
    final random = math.Random(2);
    final noise = Float32List(4096);
    for (var i = 0; i < noise.length; i++) {
      noise[i] = random.nextDouble() * 0.2 - 0.1;
    }
    expect(detectPitch(noise, 22050), isNull);
  });

  test('notas: leitura e conversões', () {
    expect(Note.parse('A4').midi, 69);
    expect(Note.parse('Eb2').label, 'E♭');
    expect(Note.parse('F#3').solfege, 'Fá♯');
    expect(Note.fromMidi(40).label, 'E');
    expect(Note.fromMidi(40).octave, 2);
    expect(midiToFreq(69, 440), closeTo(440, 1e-9));
    expect(freqToMidi(82.4069, 440), closeTo(40, 1e-3));
  });
}
