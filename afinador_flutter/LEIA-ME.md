# Afinador de Violão e Cordas

App Flutter (iOS e Android) com afinador e metrônomo. Identificador: `com.raaquino.afinador`. Marca: Bancada.

## Como montar

1. Tenha o Flutter instalado (`flutter doctor` sem erros para iOS e Android).
2. No Terminal, dentro desta pasta: `bash configurar.sh`
3. Conecte um celular e rode `flutter run`.

O script cria o projeto, copia o código de `src/`, instala as dependências, configura a permissão de microfone, baixa as fontes e roda `flutter analyze` e `flutter test`.

## Importante

Este código foi escrito sem acesso a um compilador Flutter. A lógica de detecção foi validada no protótipo web e portada linha a linha, mas o projeto ainda não foi compilado nem rodado. Se `flutter analyze`, `flutter test` ou `flutter run` apontarem erro, envie a saída para corrigir.

Pontos para testar no aparelho:

- Afinador: estabilidade da agulha, cordas graves do baixo, pedido de permissão do microfone.
- Metrônomo: som dos cliques e regularidade do andamento.
- iPhone: usar o afinador e, em seguida, o metrônomo e o botão "Ouvir corda". O iOS troca o modo de áudio entre gravar e tocar, e esse é o ponto com mais chance de precisar de ajuste.

## Estrutura

- `src/lib/core/` lógica pura: detecção de nota (YIN), afinações, síntese dos sons.
- `src/lib/audio/` microfone (`record`) e saída de som (`flutter_soloud`).
- `src/lib/ui/` telas do afinador e do metrônomo, tema e componentes.
- `src/test/` testes da detecção e do metrônomo.
