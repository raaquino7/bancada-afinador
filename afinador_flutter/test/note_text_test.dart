import 'package:afinador/ui/note_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('♯ e ♭ viram sinais desenhados; o resto continua texto', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          NoteText('C♯', style: TextStyle(fontSize: 40)),
          NoteText('Mi♭', style: TextStyle(fontSize: 15)),
          NoteText('A', style: TextStyle(fontSize: 15)),
        ]),
      ),
    );
    final signs = tester.widgetList<Accidental>(find.byType(Accidental)).toList();
    expect(signs.map((a) => a.sharp), [true, false]);
    expect(find.text('C♯', findRichText: true), findsNothing);
  });

  test('leitor de tela fala sustenido e bemol', () {
    expect(spokenNote('Fá♯'), 'Fá sustenido');
    expect(spokenNote('Mi♭'), 'Mi bemol');
  });
}
