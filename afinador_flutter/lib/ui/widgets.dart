import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'note_text.dart';
import 'theme.dart';

/// Marca: um diapasão.
class ForkIcon extends StatelessWidget {
  const ForkIcon({super.key, required this.color, this.size = 22});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _ForkPainter(color));
  }
}

class _ForkPainter extends CustomPainter {
  _ForkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintFork(canvas, Offset.zero & size, color);

  @override
  bool shouldRepaint(_ForkPainter oldDelegate) => oldDelegate.color != color;
}

/// Desenha o diapasão da marca dentro de [rect] (quadrado de 24 unidades).
/// O mesmo desenho gera o ícone do app (tool/gerar_icones_test.dart).
void paintFork(Canvas canvas, Rect rect, Color color, {double stroke = 2.4}) {
  final s = rect.width / 24;
  final o = rect.topLeft;
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke * s
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
  Offset p(double x, double y) => o + Offset(x * s, y * s);
  final path = Path()
    ..moveTo(p(7, 3).dx, p(7, 3).dy)
    ..lineTo(p(7, 11).dx, p(7, 11).dy)
    ..arcToPoint(p(17, 11), radius: Radius.circular(5 * s), clockwise: false)
    ..lineTo(p(17, 3).dx, p(17, 3).dy)
    ..moveTo(p(12, 16).dx, p(12, 16).dy)
    ..lineTo(p(12, 21).dx, p(12, 21).dy);
  canvas.drawPath(path, paint);
}

/// Mostrador de agulha: de -50 a +50 cents.
class NeedleMeter extends StatelessWidget {
  const NeedleMeter({super.key, required this.cents, required this.idle, required this.palette});
  final double cents;
  final bool idle;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final target = cents.clamp(-50.0, 50.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: const Duration(milliseconds: 110),
      builder: (context, value, child) {
        return AspectRatio(
          aspectRatio: 320 / 112,
          child: CustomPaint(painter: _NeedlePainter(value, idle, palette)),
        );
      },
    );
  }
}

class _NeedlePainter extends CustomPainter {
  _NeedlePainter(this.cents, this.idle, this.palette);
  final double cents;
  final bool idle;
  final Palette palette;

  static const double _span = 42; // graus para 50 cents

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 320;
    final center = Offset(160 * s, 186 * s);
    final radius = 140 * s;

    Offset polar(double r, double degrees) {
      final a = degrees * math.pi / 180;
      return center + Offset(r * math.sin(a), -r * math.cos(a));
    }

    final tick = Paint()
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    for (var c = -50; c <= 50; c += 5) {
      final degrees = c / 50 * _span;
      final length = c == 0 ? 20.0 : (c % 25 == 0 ? 12.0 : 7.0);
      tick.color = c == 0 ? palette.text : palette.line;
      canvas.drawLine(polar(radius, degrees), polar(radius - length * s, degrees), tick);
    }

    void label(bool sharp, double degrees) {
      final size = accidentalSize(15 * s, sharp: sharp);
      final p = polar(radius + 4 * s, degrees);
      paintAccidental(
        canvas,
        Rect.fromCenter(center: p, width: size.width, height: size.height),
        sharp: sharp,
        color: palette.muted,
        thickness: 1.3 * s,
      );
    }

    label(false, -_span - 6);
    label(true, _span + 6);

    final needle = Paint()
      ..color = idle ? palette.brand.withValues(alpha: 0.25) : palette.brand
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    final degrees = cents / 50 * _span;
    canvas.drawLine(polar(78 * s, degrees), polar(136 * s, degrees), needle);
  }

  @override
  bool shouldRepaint(_NeedlePainter oldDelegate) {
    return oldDelegate.cents != cents || oldDelegate.idle != idle || oldDelegate.palette != palette;
  }
}

/// Seletor com borda fina, usado para instrumento, afinação, compasso e subdivisão.
class PickerBox extends StatelessWidget {
  const PickerBox({
    super.key,
    required this.value,
    required this.labels,
    required this.onChanged,
    required this.palette,
  });

  final int value;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: palette.bg,
          icon: Icon(Icons.expand_more, color: palette.muted, size: 20),
          style: bodyStyle(15, palette.text, weight: FontWeight.w500),
          items: [
            for (var i = 0; i < labels.length; i++)
              DropdownMenuItem<int>(
                value: i,
                child: Text(labels[i], overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.active,
    required this.onPressed,
    required this.palette,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: active ? Colors.transparent : palette.brand,
        shape: StadiumBorder(
          side: BorderSide(color: active ? palette.line : palette.brand, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: bodyStyle(16, active ? palette.text : palette.onBrand, weight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.palette,
    this.size = 46,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Palette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          shape: CircleBorder(side: BorderSide(color: palette.line, width: 1.5)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Icon(icon, color: palette.text, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}

class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.brand, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: NoteText(
                label,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle(15, palette.brand, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
