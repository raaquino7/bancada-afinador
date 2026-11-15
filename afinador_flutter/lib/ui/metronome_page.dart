import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_out.dart';
import '../core/metronome_engine.dart';
import '../core/wav.dart';
import 'theme.dart';
import 'widgets.dart';

class _Signature {
  const _Signature(this.label, this.beats, this.strong);
  final String label;
  final int beats;
  final List<int> strong;
}

const List<_Signature> _signatures = [
  _Signature('2/4', 2, [0]),
  _Signature('3/4', 3, [0]),
  _Signature('4/4', 4, [0]),
  _Signature('5/4', 5, [0]),
  _Signature('6/8', 6, [0, 3]),
  _Signature('7/8', 7, [0]),
  _Signature('Sem acento', 1, []),
];

const List<String> _subdivisionLabels = [
  'Sem subdivisão',
  'Colcheias (2)',
  'Tercinas (3)',
  'Semicolcheias (4)',
];

String _tempoName(int bpm) {
  if (bpm < 40) return 'Grave';
  if (bpm < 60) return 'Largo';
  if (bpm < 66) return 'Larghetto';
  if (bpm < 76) return 'Adagio';
  if (bpm < 108) return 'Andante';
  if (bpm < 120) return 'Moderato';
  if (bpm < 156) return 'Allegro';
  if (bpm < 176) return 'Vivace';
  if (bpm < 200) return 'Presto';
  return 'Prestissimo';
}

class MetronomePage extends StatefulWidget {
  const MetronomePage({
    super.key,
    required this.palette,
    required this.active,
    required this.audio,
  });

  final Palette palette;
  final bool active;
  final AudioOut audio;

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> with SingleTickerProviderStateMixin {
  int _bpm = 100;
  int _signature = 2;
  int _subdivision = 0;
  bool _on = false;
  int _beat = -1;
  String _message = '';

  late final Ticker _ticker;
  MetronomeEngine? _engine;
  Timer? _pump;
  final List<int> _taps = [];
  final Stopwatch _tapClock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _loadPrefs();
  }

  @override
  void didUpdateWidget(MetronomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && _on) _stop();
  }

  @override
  void dispose() {
    _pump?.cancel();
    _ticker.dispose();
    widget.audio.stopStream();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final bpm = prefs.getInt('bpm');
      if (bpm != null && bpm >= 30 && bpm <= 260) _bpm = bpm;
      final signature = prefs.getInt('signature');
      if (signature != null && signature >= 0 && signature < _signatures.length) _signature = signature;
      final subdivision = prefs.getInt('subdivision');
      if (subdivision != null && subdivision >= 0 && subdivision < _subdivisionLabels.length) {
        _subdivision = subdivision;
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bpm', _bpm);
    await prefs.setInt('signature', _signature);
    await prefs.setInt('subdivision', _subdivision);
  }

  // ---------- Som ----------

  /// Quanto áudio fica na fila à frente do que está tocando. Uma mudança de
  /// andamento chega ao ouvido em no máximo esse tempo, sem pausa.
  static const int _leadSamples = outputSampleRate * 150 ~/ 1000;
  static const int _blockSamples = 1024;

  Future<void> _start() async {
    final signature = _signatures[_signature];
    final engine = MetronomeEngine(
      sampleRate: outputSampleRate,
      bpm: _bpm,
      beats: signature.beats,
      strongBeats: signature.strong,
      subdivision: _subdivision + 1,
    );
    try {
      await widget.audio.startStream(engine.render(_leadSamples));
    } catch (_) {
      if (mounted) setState(() => _message = 'Não foi possível tocar o som.');
      return;
    }
    if (!mounted) return;
    _engine = engine;
    _pump?.cancel();
    _pump = Timer.periodic(const Duration(milliseconds: 20), (_) => _feed());
    if (!_ticker.isActive) _ticker.start();
    setState(() {
      _on = true;
      _beat = -1;
      _message = '';
    });
  }

  /// Completa a fila até [_leadSamples] à frente do que já tocou.
  void _feed() {
    final engine = _engine;
    if (engine == null) return;
    final played = widget.audio.playedSamples;
    final missing = _leadSamples - (engine.written - played);
    if (missing <= 0) return;
    final frames = ((missing + _blockSamples - 1) ~/ _blockSamples) * _blockSamples;
    widget.audio.pushSamples(engine.render(frames));
  }

  Future<void> _stop() async {
    _pump?.cancel();
    _pump = null;
    _engine = null;
    if (_ticker.isActive) _ticker.stop();
    _on = false;
    await widget.audio.stopStream();
    if (mounted) setState(() => _beat = -1);
  }

  /// Compasso ou subdivisão novos: valem a partir do próximo clique, que passa
  /// a ser o primeiro tempo.
  void _meterChanged() {
    _savePrefs();
    final signature = _signatures[_signature];
    _engine?.setMeter(
      beats: signature.beats,
      strongBeats: signature.strong,
      subdivision: _subdivision + 1,
    );
  }

  /// Acende a bolinha do tempo que está saindo no alto-falante agora.
  void _onTick(Duration elapsed) {
    final engine = _engine;
    if (engine == null) return;
    final mark = engine.beatAt(widget.audio.playedSamples);
    if (mark != null && mark.beat != _beat) setState(() => _beat = mark.beat);
  }

  // ---------- Controles ----------

  void _setBpm(int value) {
    final clamped = value.clamp(30, 260).toInt();
    if (clamped == _bpm) return;
    setState(() => _bpm = clamped);
    _engine?.bpm = clamped;
    _savePrefs();
  }

  void _tap() {
    final now = _tapClock.elapsedMilliseconds;
    if (_taps.isNotEmpty && now - _taps.last > 2000) _taps.clear();
    _taps.add(now);
    if (_taps.length > 5) _taps.removeAt(0);
    if (_taps.length >= 2) {
      final interval = (_taps.last - _taps.first) / (_taps.length - 1);
      _setBpm((60000 / interval).round());
    }
  }

  // ---------- Tela ----------

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final signature = _signatures[_signature];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PickerBox(
                value: _signature,
                labels: [for (final s in _signatures) s.label],
                onChanged: (v) {
                  setState(() => _signature = v);
                  _meterChanged();
                },
                palette: p,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PickerBox(
                value: _subdivision,
                labels: _subdivisionLabels,
                onChanged: (v) {
                  setState(() => _subdivision = v);
                  _meterChanged();
                },
                palette: p,
              ),
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 28,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < signature.beats; i++) _beatDot(i, signature, p),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RoundButton(
                          icon: Icons.remove,
                          label: 'Diminuir 1 BPM',
                          onPressed: () => _setBpm(_bpm - 1),
                          palette: p,
                        ),
                        Text(
                          '$_bpm',
                          style: displayStyle(128, p.text).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        RoundButton(
                          icon: Icons.add,
                          label: 'Aumentar 1 BPM',
                          onPressed: () => _setBpm(_bpm + 1),
                          palette: p,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_tempoName(_bpm), style: bodyStyle(17, p.text, weight: FontWeight.w600)),
                    Text('batidas por minuto', style: bodyStyle(13, p.muted)),
                    const SizedBox(height: 14),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: p.brand,
                        inactiveTrackColor: p.line,
                        thumbColor: p.brand,
                      ),
                      child: Slider(
                        min: 30,
                        max: 260,
                        value: _bpm.toDouble(),
                        onChanged: (v) => _setBpm(v.round()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        PrimaryButton(
          label: _on ? 'Parar' : 'Iniciar',
          active: _on,
          onPressed: () => _on ? _stop() : _start(),
          palette: p,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: LinkButton(
            icon: Icons.touch_app_rounded,
            label: 'Marcar o tempo no toque',
            onPressed: _tap,
            palette: p,
          ),
        ),
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_message, style: bodyStyle(13, const Color(0xFFC2331C))),
          ),
      ],
    );
  }

  Widget _beatDot(int index, _Signature signature, Palette p) {
    final strong = signature.strong.contains(index);
    final on = index == _beat;
    final size = (strong ? 16.0 : 12.0) * (on ? 1.35 : 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? p.brand : Colors.transparent,
          border: Border.all(color: on ? p.brand : p.line, width: 1.5),
        ),
      ),
    );
  }
}
