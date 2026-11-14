import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_out.dart';
import '../audio/mic_input.dart';
import '../core/pitch.dart';
import '../core/tunings.dart';
import '../core/wav.dart';
import 'note_text.dart';
import 'theme.dart';
import 'widgets.dart';

class TunerPage extends StatefulWidget {
  const TunerPage({
    super.key,
    required this.palette,
    required this.active,
    required this.audio,
    required this.onTunedChanged,
  });

  final Palette palette;

  /// Falso quando outra aba está na tela ou o app foi para segundo plano.
  final bool active;
  final AudioOut audio;
  final ValueChanged<bool> onTunedChanged;

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  final MicInput _mic = MicInput();
  final Stopwatch _clock = Stopwatch()..start();

  int _instrument = 1; // Violão
  int _tuning = 0;
  double _a4 = 440;
  final Map<String, List<int>> _custom = {};

  bool _running = false;
  bool _toneBusy = false;
  String _message = '';

  int? _locked;
  int? _lastTarget;
  final Set<int> _tunedStrings = {};
  final List<double> _history = [];

  Note? _note;
  double _cents = 0;
  double _freq = 0;
  bool _hasReading = false;
  bool _inTune = false;
  int _inTuneSince = 0;
  int _lastHeard = 0;

  Instrument get _inst => instruments[_instrument];
  bool get _isChromatic => _inst.isChromatic;
  bool get _isCustom => !_isChromatic && _tuning == _inst.tunings.length;

  List<Note> get _strings {
    if (_isChromatic) return const [];
    if (_isCustom) {
      return _custom[_inst.id]!.map((m) => Note.fromMidi(m)).toList();
    }
    return _inst.tunings[_tuning].notes;
  }

  @override
  void initState() {
    super.initState();
    _mic.onWindow = _onWindow;
    _loadPrefs();
  }

  @override
  void didUpdateWidget(TunerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && _running) _stopMic();
  }

  @override
  void dispose() {
    _mic.dispose();
    super.dispose();
  }

  // ---------- Preferências ----------

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final id = prefs.getString('instrument');
      final index = instruments.indexWhere((i) => i.id == id);
      if (index >= 0) _instrument = index;
      final a4 = prefs.getDouble('a4');
      if (a4 != null && a4 >= 415 && a4 <= 466) _a4 = a4;
      final raw = prefs.getString('custom');
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            _custom[key] = (value as List<dynamic>).map((e) => e as int).toList();
          });
        } catch (_) {
          // Preferência corrompida: segue com os padrões.
        }
      }
      final tuning = prefs.getInt('tuning') ?? 0;
      final max = _inst.tunings.length;
      if (tuning >= 0 && (tuning < max || (tuning == max && _custom.containsKey(_inst.id)))) {
        _tuning = tuning;
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('instrument', _inst.id);
    await prefs.setInt('tuning', _tuning);
    await prefs.setDouble('a4', _a4);
    await prefs.setString('custom', jsonEncode(_custom));
  }

  // ---------- Microfone e leitura ----------

  Future<void> _startMic() async {
    setState(() => _message = '');
    bool granted;
    try {
      granted = await _mic.start();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    if (!granted) {
      setState(() {
        _message = 'Não foi possível usar o microfone. Libere o acesso nos ajustes do aparelho e tente de novo.';
      });
      return;
    }
    setState(() => _running = true);
  }

  Future<void> _stopMic() async {
    _running = false;
    await _mic.stop();
    if (!mounted) return;
    _clearReading();
  }

  void _clearReading() {
    if (!mounted) return;
    _history.clear();
    _lastHeard = 0;
    _inTuneSince = 0;
    final wasTuned = _inTune;
    setState(() {
      _hasReading = false;
      _inTune = false;
      _cents = 0;
    });
    if (wasTuned) widget.onTunedChanged(false);
  }

  void _onWindow(Float32List window) {
    if (!_running || _toneBusy) return;
    final now = _clock.elapsedMilliseconds;
    final hit = detectPitch(decimate2(window), MicInput.sampleRate / 2);
    if (hit != null && hit.clarity > 0.8) {
      final midi = freqToMidi(hit.freq, _a4);
      // Uma mudança brusca de nota recomeça a média.
      if (_history.isNotEmpty && (midi - _history.last).abs() > 0.7) _history.clear();
      _history.add(midi);
      if (_history.length > 5) _history.removeAt(0);
      final sorted = List<double>.from(_history)..sort();
      _lastHeard = now;
      _showReading(sorted[sorted.length ~/ 2], now);
    } else if (_lastHeard != 0 && now - _lastHeard > 1500) {
      _clearReading();
    }
  }

  void _showReading(double midi, int now) {
    if (!mounted) return;
    final Note target;
    int? found;
    if (_isChromatic) {
      target = Note.fromMidi(midi.round());
    } else {
      final strings = _strings;
      var best = _locked ?? 0;
      if (_locked == null) {
        for (var i = 1; i < strings.length; i++) {
          if ((midi - strings[i].midi).abs() < (midi - strings[best].midi).abs()) best = i;
        }
      }
      if (best >= strings.length) best = 0;
      target = strings[best];
      found = best;
    }
    final int? targetIndex = found;
    final cents = (midi - target.midi) * 100;
    // Entra em 4 cents e só sai em 7, para a tela não piscar na fronteira.
    final tuned = cents.abs() <= (_inTune ? 7 : 4);
    if (!tuned) {
      _inTuneSince = 0;
    } else if (_inTuneSince == 0) {
      _inTuneSince = now;
    }
    final held = tuned && now - _inTuneSince > 500;
    final changed = tuned != _inTune;
    setState(() {
      _note = target;
      _cents = cents;
      _freq = midiToFreq(midi, _a4);
      _hasReading = true;
      _inTune = tuned;
      _lastTarget = targetIndex;
      if (held && targetIndex != null) _tunedStrings.add(targetIndex);
    });
    if (changed) widget.onTunedChanged(tuned);
  }

  // ---------- Controles ----------

  void _resetSelection() {
    _locked = null;
    _lastTarget = null;
    _tunedStrings.clear();
    _history.clear();
  }

  void _selectInstrument(int index) {
    setState(() {
      _instrument = index;
      _tuning = 0;
      _resetSelection();
    });
    _clearReading();
    _savePrefs();
  }

  void _selectTuning(int index) {
    setState(() {
      if (index == _inst.tunings.length && !_custom.containsKey(_inst.id)) {
        _custom[_inst.id] = _strings.map((n) => n.midi).toList();
      }
      _tuning = index;
      _resetSelection();
    });
    _clearReading();
    _savePrefs();
  }

  void _toggleString(int index) {
    setState(() {
      _locked = _locked == index ? null : index;
      _history.clear();
    });
  }

  void _stepCustom(int index, int delta) {
    setState(() {
      final list = _custom[_inst.id]!;
      list[index] = (list[index] + delta).clamp(21, 96).toInt();
      _tunedStrings.remove(index);
    });
    _savePrefs();
  }

  void _setA4(double value) {
    setState(() => _a4 = value.clamp(415.0, 466.0).toDouble());
    _savePrefs();
  }

  Note get _toneNote {
    if (_isChromatic) return Note.fromMidi(69);
    final strings = _strings;
    final index = _locked ?? _lastTarget ?? 0;
    return strings[index < strings.length ? index : 0];
  }

  Future<void> _playTone() async {
    if (_toneBusy) return;
    const seconds = 2.4;
    final wav = wavFromSamples(toneSamples(midiToFreq(_toneNote.midi, _a4), seconds: seconds));
    setState(() => _toneBusy = true);
    try {
      await widget.audio.playOnce(wav, const Duration(milliseconds: 2400));
      await Future<void>.delayed(const Duration(milliseconds: 2500));
    } catch (_) {
      if (mounted) setState(() => _message = 'Não foi possível tocar o som.');
    }
    _history.clear();
    if (mounted) setState(() => _toneBusy = false);
  }

  // ---------- Tela ----------

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final strings = _strings;
    final lockedNote = _locked != null && _locked! < strings.length ? strings[_locked!] : null;
    final shown = _hasReading ? _note : lockedNote;

    String hint;
    if (!_hasReading) {
      hint = _running ? 'Toque uma corda' : 'Ligue o microfone e toque uma corda';
    } else if (_inTune) {
      hint = 'Afinada';
    } else {
      hint = _cents < 0 ? 'Baixa: aperte a corda' : 'Alta: afrouxe a corda';
    }
    final rounded = _cents.round();
    final sign = rounded > 0 ? '+' : (rounded < 0 ? '−' : '');
    final tone = _toneNote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PickerBox(
                value: _instrument,
                labels: [for (final i in instruments) i.name],
                onChanged: _selectInstrument,
                palette: p,
              ),
            ),
            if (!_isChromatic) ...[
              const SizedBox(width: 10),
              Expanded(
                child: PickerBox(
                  value: _tuning,
                  labels: [for (final t in _inst.tunings) t.name, 'Personalizada'],
                  onChanged: _selectTuning,
                  palette: p,
                ),
              ),
            ],
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
                    NeedleMeter(cents: _hasReading ? _cents : 0, idle: !_hasReading, palette: p),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        NoteText(
                          shown?.label ?? '–',
                          style: displayStyle(128, _hasReading ? p.text : p.line),
                        ),
                        if (shown != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 6, bottom: 14),
                            child: Text('${shown.octave}', style: bodyStyle(30, p.muted, weight: FontWeight.w500)),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: 22,
                      child: NoteText(shown?.solfege ?? '', style: bodyStyle(15, p.muted)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: bodyStyle(
                        17,
                        _hasReading ? p.text : p.muted,
                        weight: _hasReading ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: Text(
                        _hasReading ? '$sign${rounded.abs()} cents    ${_freq.toStringAsFixed(1)} Hz' : '',
                        style: bodyStyle(13, p.muted).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!_isChromatic) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < strings.length; i++)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 54),
                      child: _stringButton(i, strings[i], p),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _locked == null
                ? 'Detecção automática. Toque numa corda para fixar.'
                : 'Corda fixada. Toque nela de novo para soltar.',
            textAlign: TextAlign.center,
            style: bodyStyle(12.5, p.muted),
          ),
          const SizedBox(height: 16),
        ],
        PrimaryButton(
          label: _running ? 'Desligar microfone' : 'Ligar microfone',
          active: _running,
          onPressed: () => _running ? _stopMic() : _startMic(),
          palette: p,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: LinkButton(
                  icon: Icons.play_arrow_rounded,
                  label: _toneBusy
                      ? 'Tocando ${midiToFreq(tone.midi, _a4).toStringAsFixed(1)} Hz'
                      : (_isChromatic ? 'Ouvir Lá' : 'Ouvir corda ${tone.label}${tone.octave}'),
                  onPressed: _playTone,
                  palette: p,
                ),
              ),
            ),
            RoundButton(
              icon: Icons.remove,
              label: 'Diminuir o Lá de referência',
              onPressed: () => _setA4(_a4 - 1),
              palette: p,
              size: 30,
            ),
            SizedBox(
              width: 86,
              child: Text(
                'Lá ${_a4.round()} Hz',
                textAlign: TextAlign.center,
                style: bodyStyle(13, p.text),
              ),
            ),
            RoundButton(
              icon: Icons.add,
              label: 'Aumentar o Lá de referência',
              onPressed: () => _setA4(_a4 + 1),
              palette: p,
              size: 30,
            ),
          ],
        ),
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_message, style: bodyStyle(13, const Color(0xFFC2331C))),
          ),
      ],
    );
  }

  Widget _stringButton(int index, Note note, Palette p) {
    final locked = _locked == index;
    final target = _locked == null && _lastTarget == index;
    final tuned = _tunedStrings.contains(index);
    final foreground = locked ? p.onBrand : (target ? p.brand : p.text);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          selected: locked,
          label: 'Corda ${spokenNote(note.solfege)} ${note.octave}',
          child: GestureDetector(
            onTap: () => _toggleString(index),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: locked ? p.brand : Colors.transparent,
                        border: Border.all(color: locked || target ? p.brand : p.line, width: 1.5),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            NoteText(note.label, style: displayStyle(17, foreground).copyWith(height: 1.1)),
                            Text('${note.octave}', style: bodyStyle(10, locked ? p.onBrand : p.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (tuned)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.ok,
                          border: Border.all(color: p.bg, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_isCustom)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(child: _stepButton('−', 'Descer meio tom', () => _stepCustom(index, -1), p)),
                const SizedBox(width: 3),
                Expanded(child: _stepButton('+', 'Subir meio tom', () => _stepCustom(index, 1), p)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stepButton(String text, String label, VoidCallback onTap, Palette p) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: p.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: bodyStyle(14, p.muted)),
        ),
      ),
    );
  }
}
