import 'package:flutter/material.dart';

import 'theme.dart';

/// Política de privacidade dentro do app (o Google Play exige o acesso por
/// dentro do app). Mesmo conteúdo de loja/privacidade.html, em versão curta.
const List<(String, String)> privacySections = [
  ('', 'O app não coleta, não grava e não envia nenhum dado seu.'),
  (
    'Microfone',
    'O microfone é usado só para ouvir a corda e mostrar a nota. O som é '
        'analisado dentro do aparelho, em tempo real, e descartado em seguida. '
        'Nada é gravado e nada é enviado para a internet. O microfone desliga '
        'quando você toca em “Desligar microfone” ou sai do app.',
  ),
  (
    'Preferências',
    'Suas escolhas (instrumento, afinação, lá de referência e ajustes do '
        'metrônomo) ficam guardadas só no aparelho. Se o backup do aparelho '
        'estiver ligado, o sistema pode incluí-las no seu backup.',
  ),
  (
    'O que o app não faz',
    'Não pede cadastro. Não usa internet, anúncios, rastreamento nem análise '
        'de uso. Não compartilha dados com ninguém.',
  ),
];

void showPrivacy(BuildContext context, Palette p) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.bg,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Política de privacidade',
                    style: displayStyle(22, p.text),
                  ),
                  const SizedBox(height: 12),
                  for (final (title, body) in privacySections) ...[
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: bodyStyle(15, p.text, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      body,
                      style: bodyStyle(
                        14.5,
                        title.isEmpty ? p.text : p.muted,
                      ).copyWith(height: 1.45),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
