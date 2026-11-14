import 'package:flutter/material.dart';

/// Identidade: tela neutra, azul-cobalto só na marca, na agulha e no botão
/// principal. Quando a corda afina, a tela inteira fica verde.
class Palette {
  const Palette({
    required this.bg,
    required this.text,
    required this.muted,
    required this.line,
    required this.brand,
    required this.onBrand,
    required this.ok,
  });

  final Color bg;
  final Color text;
  final Color muted;
  final Color line;
  final Color brand;
  final Color onBrand;
  final Color ok;

  static const Color tune = Color(0xFF3DDC9D);

  static const Palette light = Palette(
    bg: Color(0xFFF4F4F1),
    text: Color(0xFF15171C),
    muted: Color(0xFF6D727E),
    line: Color(0xFFD9DBE0),
    brand: Color(0xFF2747F5),
    onBrand: Color(0xFFFFFFFF),
    ok: Color(0xFF0C9A6B),
  );

  static const Palette dark = Palette(
    bg: Color(0xFF0E1014),
    text: Color(0xFFF1F2F4),
    muted: Color(0xFF8A90A0),
    line: Color(0xFF272B35),
    brand: Color(0xFF7189FF),
    onBrand: Color(0xFF0E1014),
    ok: Color(0xFF3DDC9D),
  );

  static const Palette inTune = Palette(
    bg: tune,
    text: Color(0xFF05281B),
    muted: Color.fromRGBO(5, 40, 27, 0.66),
    line: Color.fromRGBO(5, 40, 27, 0.24),
    brand: Color(0xFF05281B),
    onBrand: tune,
    ok: Color(0xFF05281B),
  );
}

const String displayFont = 'Bricolage';
const String bodyFont = 'InstrumentSans';

TextStyle displayStyle(double size, Color color) {
  return TextStyle(
    fontFamily: displayFont,
    fontSize: size,
    fontWeight: FontWeight.w800,
    fontVariations: const [FontVariation('wght', 800)],
    height: 0.95,
    letterSpacing: -size * 0.03,
    color: color,
  );
}

TextStyle bodyStyle(double size, Color color, {FontWeight weight = FontWeight.w400}) {
  return TextStyle(
    fontFamily: bodyFont,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color,
  );
}
