// O app precisa caber em qualquer janela: iPhone em retrato e, no iPad, janelas
// de qualquer tamanho e orientação (multitarefa do iPadOS 26).
import 'package:afinador/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const sizes = <String, Size>{
  'iPhone SE (retrato)': Size(375, 667),
  'iPhone 17 Pro (retrato)': Size(402, 874),
  'iPad 13 (retrato)': Size(1032, 1376),
  'iPad 13 (paisagem)': Size(1376, 1032),
  'iPad mini (paisagem)': Size(1133, 744),
  'iPad, janela estreita': Size(320, 900),
  'iPad, janela baixa e larga': Size(900, 420),
  'iPad, janela pequena': Size(400, 360),
};

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(path));
  await loader.load();
}

void main() {
  // Sem isso o teste usa uma fonte de blocos, mais larga que as do app.
  setUpAll(() async {
    await _loadFont('Bricolage', 'assets/fonts/Bricolage.ttf');
    await _loadFont('InstrumentSans', 'assets/fonts/InstrumentSans.ttf');
  });

  for (final entry in sizes.entries) {
    for (final tab in ['Afinador', 'Metrônomo']) {
      testWidgets('${entry.key}, $tab: sem estouro', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const AfinadorApp());
        await tester.pump();
        if (tab == 'Metrônomo') {
          await tester.tap(find.text('Metrônomo'));
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Rodapé abre a política de privacidade', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const AfinadorApp());
    await tester.tap(find.text('Privacidade'));
    await tester.pumpAndSettle();
    expect(find.text('Política de privacidade'), findsOneWidget);
    expect(find.text('Microfone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
