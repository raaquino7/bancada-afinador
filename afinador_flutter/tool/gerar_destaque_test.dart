// Gera o gráfico de destaque do Google Play (1024 x 500, sem transparência).
// Não faz parte dos testes normais.
//
// Uso, na pasta afinador_flutter:  flutter test tool/gerar_destaque_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:afinador/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const cobalto = Color(0xFF2747F5);
const branco = Color(0xFFFFFFFF);
const brancoSuave = Color(0xCCFFFFFF);

Future<void> _fonte(String familia, String caminho) async {
  final loader = FontLoader(familia)..addFont(rootBundle.load(caminho));
  await loader.load();
}

TextPainter _texto(String texto, String familia, double tamanho, Color cor, FontWeight peso) {
  return TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(fontFamily: familia, fontSize: tamanho, color: cor, fontWeight: peso, height: 1.1),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 640);
}

void main() {
  testWidgets('gera o gráfico de destaque', (tester) async {
    await tester.runAsync(() async {
      await _fonte('Bricolage', 'assets/fonts/Bricolage.ttf');
      await _fonte('InstrumentSans', 'assets/fonts/InstrumentSans.ttf');

      const w = 1024.0, h = 500.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = cobalto);

      // Diapasão à esquerda, no mesmo traço do ícone.
      const lado = 24 * 13.0;
      paintFork(canvas, Rect.fromCenter(center: const Offset(225, h / 2), width: lado, height: lado), branco, stroke: 2.6);

      // Nome e frase à direita.
      final titulo = _texto('Afinador de\nViolão e Cordas', 'Bricolage', 54, branco, FontWeight.w700);
      final frase = _texto('Afinador e metrônomo.\nToque a corda e veja a tela ficar verde.', 'InstrumentSans', 25, brancoSuave, FontWeight.w400);
      final marca = _texto('um app Bancada', 'InstrumentSans', 20, brancoSuave, FontWeight.w600);
      const x = 420.0;
      final total = titulo.height + 22 + frase.height + 30 + marca.height;
      var y = (h - total) / 2;
      titulo.paint(canvas, Offset(x, y));
      y += titulo.height + 22;
      frase.paint(canvas, Offset(x, y));
      y += frase.height + 30;
      marca.paint(canvas, Offset(x, y));

      final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('loja/google_play_destaque_1024x500.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
