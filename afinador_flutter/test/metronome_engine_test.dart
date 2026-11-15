import 'package:afinador/core/metronome_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const int rate = 48000;

/// Gera [total] amostras em blocos de [block], como o app faz.
void run(MetronomeEngine e, int total, {int block = 1024}) {
  var left = total;
  while (left > 0) {
    final n = left < block ? left : block;
    e.render(n);
    left -= n;
  }
}

List<int> samples(MetronomeEngine e) => [for (final m in e.marks) m.sample];
List<int> beats(MetronomeEngine e) => [for (final m in e.marks) m.beat];

void main() {
  test('120 BPM em 4/4: um tempo a cada meio segundo, exato', () {
    final e = MetronomeEngine(sampleRate: rate, bpm: 120);
    run(e, rate * 3);
    expect(samples(e), [0, 24000, 48000, 72000, 96000, 120000]);
    expect(beats(e), [0, 1, 2, 3, 0, 1]);
  });

  test('blocos de tamanhos diferentes geram o mesmo som', () {
    final a = MetronomeEngine(sampleRate: rate, bpm: 97, subdivision: 3);
    final b = MetronomeEngine(sampleRate: rate, bpm: 97, subdivision: 3);
    final outA = [for (var i = 0; i < 40; i++) ...a.render(1024)];
    final outB = [for (var i = 0; i < 80; i++) ...b.render(512)];
    expect(outA, outB);
  });

  test('mudar o andamento vale no próximo clique, sem voltar ao início', () {
    final e = MetronomeEngine(sampleRate: rate, bpm: 120);
    run(e, 30000); // tocou os tempos 0 e 1
    e.bpm = 60;
    run(e, rate * 2);
    // O tempo 2 vem um segundo (60 BPM) depois do tempo 1, sem pausa extra.
    expect(samples(e).take(3), [0, 24000, 72000]);
    expect(beats(e).take(4), [0, 1, 2, 3]);
  });

  test('acelerar muito toca o clique atrasado na hora, sem pular', () {
    final e = MetronomeEngine(sampleRate: rate, bpm: 30); // 2 s por tempo
    run(e, 50000);
    e.bpm = 240; // 0,25 s por tempo: o próximo já estaria no passado
    run(e, 30000, block: 10000);
    expect(samples(e), [0, 50000, 62000, 74000]);
  });

  test('o andamento continua contínuo depois de várias mudanças', () {
    final e = MetronomeEngine(sampleRate: rate, bpm: 100);
    for (final bpm in [101, 102, 103, 104, 105]) {
      e.bpm = bpm;
      run(e, rate);
    }
    final s = samples(e);
    for (var i = 1; i < s.length; i++) {
      final gap = s[i] - s[i - 1];
      // Entre 100 e 105 BPM o intervalo fica entre 27428 e 28800 amostras.
      expect(gap, inInclusiveRange(27428, 28800), reason: 'intervalo $i');
    }
  });

  test('trocar o compasso recomeça no primeiro tempo, sem pausa', () {
    final e = MetronomeEngine(sampleRate: rate, bpm: 120);
    run(e, 30000);
    e.setMeter(beats: 6, strongBeats: const [0, 3], subdivision: 1);
    run(e, rate);
    // O tempo 2 do 4/4 não chega a tocar: no lugar dele vem o 1 do 6/8,
    // no mesmo ponto em que viria, sem atraso.
    expect(beats(e), [0, 1, 0, 1]);
    expect(samples(e), [0, 24000, 48000, 72000]);
  });

  test('subdivisão: cliques entre os tempos, marcas só nos tempos', () {
    final e = MetronomeEngine(sampleRate: rate, bpm: 60, subdivision: 4);
    final out = e.render(rate);
    expect(samples(e), [0]);
    for (final at in [12000, 24000, 36000]) {
      expect(out[at + 10].abs(), greaterThan(0.01), reason: 'clique em $at');
    }
    expect(out[6000], 0); // silêncio entre os cliques
  });

  test('a tela acha o tempo que está tocando e descarta os antigos', () {
    final e = MetronomeEngine(sampleRate: rate, bpm: 120);
    run(e, rate * 2);
    expect(e.beatAt(-1), isNull);
    expect(e.beatAt(30000)!.beat, 1);
    expect(e.beatAt(72000)!.beat, 3);
    expect(e.marks.first.sample, 72000);
  });
}
