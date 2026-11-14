# Afinador de Violão e Cordas

App Flutter (iOS e Android) com afinador e metrônomo. Identificador: `com.raaquino.afinador`. Marca: Bancada.

## Como rodar

1. `flutter pub get`
2. `flutter analyze` e `flutter test`
3. `flutter run` (simulador, emulador ou aparelho conectado)

O protótipo web de referência (comportamento e visual) está em `../tarraxa.html`.

## Estrutura

- `lib/core/` lógica pura: detecção de nota (YIN), afinações, síntese dos sons.
- `lib/audio/` microfone (`record`) e saída de som (`flutter_soloud`).
- `lib/ui/` telas do afinador e do metrônomo, tema e componentes.
- `test/` testes da detecção e do metrônomo.
