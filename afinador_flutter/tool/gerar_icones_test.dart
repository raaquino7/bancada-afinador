// Gera o ícone do app e as imagens da tela de abertura com o mesmo desenho do
// diapasão usado no app (paintFork). Não faz parte dos testes normais.
//
// Uso, na pasta afinador_flutter:  flutter test tool/gerar_icones_test.dart
// Depois:  dart run flutter_launcher_icons  e  dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:afinador/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const cobalto = Color(0xFF2747F5);
const cobaltoEscuro = Color(0xFF7189FF); // a marca no tema escuro
const branco = Color(0xFFFFFFFF);

/// O desenho ocupa y de 3 a 21 no quadro de 24 (centro vertical em 12).
/// [escala] = pixels por unidade do quadro.
Future<void> gerar(
  String caminho, {
  required int tamanho,
  required double escala,
  required Color cor,
  Color? fundo,
  double traco = 2.6,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final n = tamanho.toDouble();
  if (fundo != null) canvas.drawRect(Rect.fromLTWH(0, 0, n, n), Paint()..color = fundo);
  final lado = 24 * escala;
  paintFork(
    canvas,
    Rect.fromCenter(center: Offset(n / 2, n / 2), width: lado, height: lado),
    cor,
    stroke: traco,
  );
  final image = await recorder.endRecording().toImage(tamanho, tamanho);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(caminho);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('gerado $caminho ($tamanho px)');
}

void main() {
  testWidgets('gera ícones e abertura', (tester) async {
    await tester.runAsync(() async {
      // Ícone principal (iOS, Android antigo): quadrado cheio, sem cantos
      // arredondados; os sistemas aplicam a máscara.
      await gerar('assets/icon/icone.png', tamanho: 1024, escala: 31, cor: branco, fundo: cobalto);
      // iOS 18+: variantes escura e tingida, com fundo transparente (o sistema
      // põe o fundo). Sem elas o iOS gera as suas automaticamente.
      await gerar('assets/icon/icone_escuro.png', tamanho: 1024, escala: 31, cor: cobaltoEscuro);
      await gerar('assets/icon/icone_tingido.png', tamanho: 1024, escala: 31, cor: branco);
      // Google Play: 512 x 512, quadrado cheio, sem transparência.
      await gerar('loja/google_play_icone_512.png', tamanho: 512, escala: 15.5, cor: branco, fundo: cobalto);
      // Android adaptativo: camada de 108 dp. O desenho tem cerca de 49 dp de
      // altura: passa do mínimo de 48 dp e fica bem dentro da zona segura de
      // 66 dp, com o mesmo respiro dos outros ícones do sistema.
      await gerar('assets/icon/adaptativo_frente.png', tamanho: 1024, escala: 22.5, cor: branco);
      // Camada monocromática (ícones temáticos do Android 13+).
      await gerar('assets/icon/adaptativo_mono.png', tamanho: 1024, escala: 22.5, cor: branco);
      // Abertura: diapasão na cor da marca sobre a tela neutra.
      await gerar('assets/splash/abertura.png', tamanho: 768, escala: 19, cor: cobalto);
      await gerar('assets/splash/abertura_escura.png', tamanho: 768, escala: 19, cor: cobaltoEscuro);
      // Android 12+: ícone sem fundo, 288 dp, desenho dentro do círculo de
      // 192 dp (768 px de 1152).
      await gerar('assets/splash/abertura_android12.png', tamanho: 1152, escala: 28, cor: cobalto);
      await gerar('assets/splash/abertura_android12_escura.png', tamanho: 1152, escala: 28, cor: cobaltoEscuro);
    });
  });
}
