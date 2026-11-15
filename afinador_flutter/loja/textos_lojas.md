# Textos das lojas (pt-BR)

Limites conferidos nas páginas oficiais em 15/11/2026. Os tamanhos são checados
por `python3 loja/conferir_textos.py`.

A descrição completa é a mesma nas duas lojas: [descricao_completa.txt](descricao_completa.txt).

## Google Play

| Campo | Texto | Limite |
|---|---|---|
| Nome do app | Afinador de Violão e Cordas | 30 |
| Descrição curta | Afine violão, guitarra, baixo, ukulele e cavaquinho. Com metrônomo. | 80 |
| Descrição completa | descricao_completa.txt | 4000 |
| Categoria | Música e áudio | |
| Ícone | google_play_icone_512.png | 512 × 512 |

## App Store

| Campo | Texto | Limite |
|---|---|---|
| Nome | Afinador de Violão e Cordas | 30 |
| Subtítulo | Metrônomo, guitarra e ukulele | 30 |
| Texto promocional | Ligue o microfone, toque a corda e veja a tela ficar verde quando ela afinar. Inclui metrônomo com compassos e subdivisões. | 170 |
| Palavras-chave | (abaixo) | 100 bytes |
| Descrição | descricao_completa.txt | 4000 |
| Categoria principal | Música | |
| Categoria secundária | Utilidades | |

Palavras-chave (vírgula sem espaço; não repetem palavras do nome nem do
subtítulo, que a App Store já usa na busca; sem nomes de outros apps ou marcas):

```
cavaquinho,baixo,bandolim,violino,cromático,afinar,diapasão,tuner,bpm,tempo,corda,instrumento
```

## Capturas de tela e gráficos

Conferidos por `python3 loja/conferir_capturas.py`. Ordem sugerida de envio: 1 a 5.

| Loja | Pasta | Tamanho | Regra oficial |
|---|---|---|---|
| App Store, iPhone | capturas/iPhone_17_Pro | 1206 × 2622 | obrigatório: iPhone com Dynamic Island (tela média) |
| App Store, iPad | capturas/iPad_Pro_13inch_M5 | 2064 × 2752 | obrigatório se o app roda no iPad: iPad 13" |
| Google Play, celular | capturas/Android_1080x1920 | 1080 × 1920 | 2 a 8; lado maior até o dobro do menor |
| Google Play, destaque | google_play_destaque_1024x500.png | 1024 × 500 | obrigatório |
| Google Play, ícone | google_play_icone_512.png | 512 × 512 | obrigatório |

1. Afinando: violão, corda Lá um pouco baixa (−21 cents).
2. Afinado: a tela fica verde.
3. Metrônomo tocando.
4. Lista de instrumentos.
5. Tema escuro: ukulele, corda Sol um pouco alta.

As leituras das telas 1, 2 e 5 vêm da detecção de verdade do app, alimentada por
um tom sintético (modo de captura, só em debug: `--dart-define=CAPTURA_HZ=...`).
Roteiro em `tool/captura.sh`.

## Endereços (GitHub Pages)

- Política de privacidade (as duas lojas): https://raaquino7.github.io/bancada-afinador/privacidade.html
- Suporte (App Store) e site do app: https://raaquino7.github.io/bancada-afinador/
- E-mail de contato: aquino.rafael@gmail.com

## Privacidade nas lojas

- **App Store, Privacidade do app:** "Dados não coletados". A Apple define coletar como
  transmitir dados para fora do aparelho; o que é processado só no aparelho não é coletado.
- **Google Play, Segurança dos dados:** o app não coleta nem compartilha dados.
  O Google define coletar como transmitir dados para fora do aparelho do usuário.
- **Política de privacidade:** [docs/privacidade.html](../../docs/privacidade.html), publicada pelo GitHub Pages. As duas lojas exigem
  um endereço público (https, página comum, não PDF). O Google Play também exige o link
  dentro do app: está no rodapé ("Privacidade").

## Pendências (dependem de você)

- Preço: os textos não falam de preço.
