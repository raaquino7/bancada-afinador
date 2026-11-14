import 'pitch.dart';

class Tuning {
  const Tuning(this.name, this.notes);
  final String name;
  final List<Note> notes;
}

class Instrument {
  const Instrument(this.id, this.name, this.tunings);
  final String id;
  final String name;
  final List<Tuning> tunings;

  bool get isChromatic => tunings.isEmpty;
}

Tuning _t(String name, String notes) {
  return Tuning(name, notes.split(' ').map((s) => Note.parse(s)).toList());
}

final List<Instrument> instruments = [
  const Instrument('chromatic', 'Cromático', []),
  Instrument('violao', 'Violão', [
    _t('Padrão', 'E2 A2 D3 G3 B3 E4'),
    _t('Drop D', 'D2 A2 D3 G3 B3 E4'),
    _t('Meio tom abaixo', 'Eb2 Ab2 Db3 Gb3 Bb3 Eb4'),
    _t('Um tom abaixo', 'D2 G2 C3 F3 A3 D4'),
    _t('DADGAD', 'D2 A2 D3 G3 A3 D4'),
    _t('Open G', 'D2 G2 D3 G3 B3 D4'),
    _t('Open D', 'D2 A2 D3 F#3 A3 D4'),
    _t('Open E', 'E2 B2 E3 G#3 B3 E4'),
  ]),
  Instrument('guitarra', 'Guitarra', [
    _t('Padrão', 'E2 A2 D3 G3 B3 E4'),
    _t('Drop D', 'D2 A2 D3 G3 B3 E4'),
    _t('Meio tom abaixo', 'Eb2 Ab2 Db3 Gb3 Bb3 Eb4'),
    _t('Um tom abaixo', 'D2 G2 C3 F3 A3 D4'),
    _t('Drop C', 'C2 G2 C3 F3 A3 D4'),
    _t('Open G', 'D2 G2 D3 G3 B3 D4'),
    _t('Open D', 'D2 A2 D3 F#3 A3 D4'),
    _t('Open E', 'E2 B2 E3 G#3 B3 E4'),
  ]),
  Instrument('baixo4', 'Baixo 4 cordas', [
    _t('Padrão', 'E1 A1 D2 G2'),
    _t('Drop D', 'D1 A1 D2 G2'),
    _t('Meio tom abaixo', 'Eb1 Ab1 Db2 Gb2'),
    _t('Um tom abaixo', 'D1 G1 C2 F2'),
  ]),
  Instrument('baixo5', 'Baixo 5 cordas', [
    _t('Padrão (Si grave)', 'B0 E1 A1 D2 G2'),
    _t('Dó agudo', 'E1 A1 D2 G2 C3'),
  ]),
  Instrument('ukulele', 'Ukulele', [
    _t('Padrão (Sol agudo)', 'G4 C4 E4 A4'),
    _t('Sol grave', 'G3 C4 E4 A4'),
    _t('Barítono', 'D3 G3 B3 E4'),
    _t('Em Ré', 'A4 D4 F#4 B4'),
  ]),
  Instrument('cavaquinho', 'Cavaquinho', [
    _t('Padrão (Ré Sol Si Ré)', 'D4 G4 B4 D5'),
    _t('Natural (Ré Sol Si Mi)', 'D4 G4 B4 E5'),
    _t('Bandolim', 'G3 D4 A4 E5'),
  ]),
  Instrument('violino', 'Violino', [
    _t('Padrão', 'G3 D4 A4 E5'),
  ]),
  Instrument('bandolim', 'Bandolim', [
    _t('Padrão', 'G3 D4 A4 E5'),
  ]),
];
