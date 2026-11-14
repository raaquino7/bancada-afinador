import 'package:flutter/material.dart';

/// As fontes da marca (Bricolage e Instrument Sans) não têm os sinais ♯ e ♭,
/// e o símbolo de reserva do sistema varia ou some conforme o aparelho.
/// Por isso os dois sinais são desenhados, com a espessura do texto ao redor.

const String sharpSign = '♯';
const String flatSign = '♭';

/// Largura e altura do sinal em relação ao tamanho da fonte.
const double _sharpWidth = 0.46;
const double _flatWidth = 0.32;
const double _signHeight = 0.64;

double _thickness(double fontSize, FontWeight? weight) {
  final w = (weight ?? FontWeight.w400).value;
  return fontSize * (0.05 + 0.07 * (w / 900));
}

/// Desenha ♯ ou ♭ dentro do retângulo [rect], com a base no fundo do retângulo.
void paintAccidental(
  Canvas canvas,
  Rect rect, {
  required bool sharp,
  required Color color,
  required double thickness,
}) {
  final w = rect.width;
  final h = rect.height;
  final o = rect.topLeft;
  if (sharp) {
    final stem = Paint()
      ..color = color
      ..strokeWidth = thickness * 0.62;
    canvas.drawLine(o + Offset(0.33 * w, 0.10 * h), o + Offset(0.33 * w, h), stem);
    canvas.drawLine(o + Offset(0.69 * w, 0), o + Offset(0.69 * w, 0.90 * h), stem);
    final bar = thickness * 0.95;
    final rise = 0.14 * h;
    final fill = Paint()..color = color;
    for (final yc in [0.31 * h, 0.71 * h]) {
      final left = yc + rise / 2;
      final right = yc - rise / 2;
      canvas.drawPath(
        Path()
          ..moveTo(o.dx + 0.04 * w, o.dy + left - bar / 2)
          ..lineTo(o.dx + 0.96 * w, o.dy + right - bar / 2)
          ..lineTo(o.dx + 0.96 * w, o.dy + right + bar / 2)
          ..lineTo(o.dx + 0.04 * w, o.dy + left + bar / 2)
          ..close(),
        fill,
      );
    }
  } else {
    final x = 0.22 * w;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(o + Offset(x, 0), o + Offset(x, h), stroke..strokeCap = StrokeCap.butt);
    canvas.drawPath(
      Path()
        ..moveTo(o.dx + x, o.dy + 0.62 * h)
        ..cubicTo(o.dx + 0.50 * w, o.dy + 0.42 * h, o.dx + 1.02 * w, o.dy + 0.48 * h, o.dx + 0.86 * w, o.dy + 0.70 * h)
        ..cubicTo(o.dx + 0.76 * w, o.dy + 0.84 * h, o.dx + 0.48 * w, o.dy + 0.94 * h, o.dx + x, o.dy + h),
      stroke..strokeCap = StrokeCap.round,
    );
  }
}

/// Tamanho do sinal desenhado para uma fonte de [fontSize].
Size accidentalSize(double fontSize, {required bool sharp}) {
  return Size(fontSize * (sharp ? _sharpWidth : _flatWidth), fontSize * _signHeight);
}

class Accidental extends StatelessWidget {
  const Accidental({
    super.key,
    required this.sharp,
    required this.fontSize,
    required this.color,
    this.weight,
  });

  final bool sharp;
  final double fontSize;
  final Color color;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    final size = accidentalSize(fontSize, sharp: sharp);
    // Um pequeno respiro dos dois lados, como o espaçamento de uma letra.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.03),
      child: CustomPaint(
        size: size,
        painter: _AccidentalPainter(sharp, color, _thickness(fontSize, weight)),
      ),
    );
  }
}

class _AccidentalPainter extends CustomPainter {
  _AccidentalPainter(this.sharp, this.color, this.thickness);
  final bool sharp;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    paintAccidental(canvas, Offset.zero & size, sharp: sharp, color: color, thickness: thickness);
  }

  @override
  bool shouldRepaint(_AccidentalPainter old) {
    return old.sharp != sharp || old.color != color || old.thickness != thickness;
  }
}

/// Texto com ♯ e ♭ desenhados. O resto do texto usa [style] normalmente.
InlineSpan noteSpan(String text, TextStyle style) {
  final children = <InlineSpan>[];
  final buffer = StringBuffer();
  void flush() {
    if (buffer.isEmpty) return;
    children.add(TextSpan(text: buffer.toString()));
    buffer.clear();
  }

  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == sharpSign || ch == flatSign) {
      flush();
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Accidental(
            sharp: ch == sharpSign,
            fontSize: style.fontSize ?? 14,
            color: style.color ?? const Color(0xFF000000),
            weight: style.fontWeight,
          ),
        ),
      );
    } else {
      buffer.write(ch);
    }
  }
  flush();
  return TextSpan(style: style, children: children);
}

/// Nome falado das notas para leitores de tela.
String spokenNote(String text) {
  return text.replaceAll(sharpSign, ' sustenido').replaceAll(flatSign, ' bemol');
}

class NoteText extends StatelessWidget {
  const NoteText(this.text, {super.key, required this.style, this.textAlign, this.overflow});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      noteSpan(text, style),
      textAlign: textAlign,
      overflow: overflow,
      semanticsLabel: spokenNote(text),
    );
  }
}
