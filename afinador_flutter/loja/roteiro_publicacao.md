# Roteiro de publicação

Passo a passo manual para publicar o **Afinador de Violão e Cordas** no Google Play e
na App Store, como pessoa física. Regras conferidas nas páginas oficiais em 15/11/2026.
As telas dos consoles mudam de vez em quando: se um nome de botão não bater, procure
o equivalente.

Tudo o que as lojas pedem já está em `afinador_flutter/loja/`:

| O quê | Onde |
|---|---|
| Nome, descrição curta, subtítulo, palavras-chave, texto promocional | [textos_lojas.md](textos_lojas.md) |
| Descrição completa | [descricao_completa.txt](descricao_completa.txt) |
| Capturas (iPhone, iPad, Android) | [capturas/](capturas/) |
| Ícone e gráfico de destaque do Google Play | `google_play_icone_512.png`, `google_play_destaque_1024x500.png` |
| Política de privacidade | https://raaquino7.github.io/bancada-afinador/privacidade.html |
| Site e suporte | https://raaquino7.github.io/bancada-afinador/ |
| E-mail de contato | aquino.rafael@gmail.com |

**Comece pelo Google Play.** O teste fechado obrigatório leva pelo menos 14 dias, e a
App Store pode ser feita em paralelo.

---

## 0. Antes de enviar: testes no aparelho

O som e o microfone só podem ser validados num aparelho de verdade. Faça isto num
iPhone (pelo TestFlight, passo C5) e num Android (pelo teste fechado, passo B5):

- [ ] Afinar uma corda de verdade: a nota certa aparece e a tela fica verde.
- [ ] "Ouvir corda": a nota de referência toca alto o suficiente.
- [ ] Alternar várias vezes: microfone → nota de referência → metrônomo → microfone. O som não pode sumir.
- [ ] Chave de silencioso ligada (iPhone): o metrônomo e a nota continuam tocando.
- [ ] Fone Bluetooth: o som vai para o fone e o microfone continua sendo o do aparelho.
- [ ] Sair do app e voltar: o microfone desliga ao sair e liga de novo pelo botão.
- [ ] Metrônomo: mudar o BPM tocando, sem pausa; testar 260 BPM com semicolcheias.
- [ ] Recusar a permissão do microfone: aparece a mensagem pedindo para liberar nos ajustes.

---

## A. Guarde antes de tudo

- **Chave de envio do Android:** `/Users/rafaelaquino/chaves/afinador-upload.jks` e a
  senha. Faça uma cópia fora do Mac. Sem ela, novas versões exigem pedir a troca de
  chave ao Google.
- O identificador `com.raaquino.afinador` não muda mais depois do primeiro envio,
  em nenhuma das lojas.

---

## B. Google Play

### B1. Conta de desenvolvedor (você já começou)

- Taxa única de US$ 25, maioridade (18+), documento e cartão no seu nome civil.
- **Verificação do aparelho:** no Play Console (web), em Início, abra "Verificar se
  você tem acesso a um dispositivo móvel Android" → Ver detalhes → leia o QR code com
  o app **Play Console** num Android físico com Android 10 ou mais novo, sem root →
  toque em Verificar. Leva menos de um minuto.

### B2. Criar o app

Play Console → **Criar app**:

- Nome do app: `Afinador de Violão e Cordas`
- Idioma padrão: Português (Brasil)
- App ou jogo: **App**
- Gratuito ou pago: **Gratuito**. (Não consegui confirmar na página oficial se dá para
  mudar de gratuito para pago depois; se pensa em cobrar no futuro, confira no Console
  antes de criar.)
- E-mail de contato: aquino.rafael@gmail.com
- Aceite as declarações (políticas do programa, leis de exportação dos EUA e termos
  da Assinatura de apps do Google Play) → **Criar app**.

### B3. Conteúdo do app (Painel → "Configurar seu app")

Todas as tarefas obrigatórias precisam estar completas antes de publicar.

| Tarefa | Resposta |
|---|---|
| Política de privacidade | https://raaquino7.github.io/bancada-afinador/privacidade.html |
| Acesso ao app | Todas as funções estão disponíveis sem acesso especial (não há login) |
| Anúncios | Não, o app não contém anúncios |
| Classificação do conteúdo | Preencha o questionário IARC. Na categoria, escolha a que mais se aproxima de utilitário/ferramenta. Responda **não** a violência, sexo, linguagem, drogas, jogos de azar, interação entre usuários, compartilhamento de localização e compras. O e-mail para o certificado é o de contato. |
| Público-alvo e conteúdo | Faixas etárias a partir de **13 anos**. Incluir menores de 13 coloca o app nas regras do programa Famílias, que exigem mais. A escolha é sua; o app não tem nada impróprio. |
| Segurança dos dados | **O app não coleta nem compartilha dados.** O Google define coletar como transmitir para fora do aparelho, e o app não usa internet. Responda "Não" à coleta. |
| Apps governamentais, recursos financeiros, saúde, notícias (se aparecerem) | Não |

O Google pede uma declaração à parte só para permissões de alto risco, como SMS e
registro de chamadas. Se o Console pedir algo sobre o microfone (`RECORD_AUDIO`),
explique: "usado só para detectar a nota tocada, no aparelho; nada é gravado ou enviado".

### B4. Ficha da loja (Crescimento → Presença na loja → Ficha principal)

- Nome, descrição curta e descrição completa: copie de `textos_lojas.md` e `descricao_completa.txt`.
- Ícone: `google_play_icone_512.png`.
- Gráfico de destaque: `google_play_destaque_1024x500.png`.
- Capturas de celular: as 5 de `capturas/Android_1080x1920/`, na ordem 1 a 5.
- Categoria: **Música e áudio**. E-mail: aquino.rafael@gmail.com. Site: https://raaquino7.github.io/bancada-afinador/

### B5. Teste fechado (obrigatório: 12 testadores por 14 dias seguidos)

A regra vale para contas pessoais criadas depois de 13/11/2023: pelo menos
**12 testadores inscritos sem interrupção por pelo menos 14 dias** antes de pedir
acesso à produção. Quem sai e volta reinicia a própria contagem.

1. **Gerar o pacote assinado** (eu faço, ou você roda na pasta `afinador_flutter`):
   ```bash
   flutter build appbundle --release
   ```
   Arquivo: `build/app/outputs/bundle/release/app-release.aab`, assinado com a sua chave
   de envio. Na primeira vez, o Google ativa sozinho a assinatura de apps do Google Play.
2. **Testes → Teste fechado → Gerenciar faixa → aba Testadores → Criar lista de e-mails.**
   Ponha os e-mails das contas Google dos testadores (até 2.000 por lista). Em
   "URL ou e-mail de feedback", use aquino.rafael@gmail.com. Salve.
3. **Aba Versões → Criar nova versão** → envie o `app-release.aab` → notas da versão
   (ex.: "Primeira versão de teste.") → Avançar → **Lançar na faixa de teste fechado**.
4. Quando o status ficar **Publicado**, aparece o **link de participação** na aba
   Testadores. Antes disso o link não aparece.
5. Mande o link para os testadores (modelo abaixo). Cada um precisa abrir o link com a
   mesma conta Google da lista, tocar em **Tornar-se testador** e instalar pelo
   Google Play.

**Dica:** chame **15 ou mais** pessoas. Se alguém sair no meio, ainda sobram 12.
Na prática, conte os 14 dias a partir do dia em que o 12º testador entrou, e confira
o andamento no Painel do Console.

Modelo de mensagem para os testadores:

> Oi! Estou publicando um app de afinador de violão e cordas, com metrônomo, e o Google
> exige um teste com pelo menos 12 pessoas por 14 dias antes de liberar na loja.
> Você me ajuda? Precisa de um celular Android e de 2 minutos:
> 1. Me passe o e-mail da sua conta Google (o mesmo do Play Store).
> 2. Quando eu avisar, abra este link no celular e toque em "Tornar-se testador": LINK
> 3. Instale o app pelo Google Play e use pelo menos uma vez.
> 4. **Não desinstale nem saia do teste por 14 dias.** Depois pode fazer o que quiser.
> Se achar algum problema ou tiver sugestão, me conte. Obrigado!

Durante os 14 dias, anote o que os testadores disserem: o pedido de produção pergunta isso.

### B6. Pedir acesso à produção

Depois dos 14 dias, no **Painel → Solicitar acesso à produção**. São três blocos de perguntas:

1. **Sobre o teste fechado:** se foi fácil recrutar testadores, se usaram todos os
   recursos, se o uso foi parecido com o esperado em produção, um resumo do feedback e
   como você o coletou.
2. **Sobre o app:** público-alvo (músicos iniciantes e intermediários que precisam
   afinar o instrumento e praticar com metrônomo), proposta de valor (afinador simples,
   sem anúncios, sem cadastro, que funciona offline, com tela verde quando afina e
   metrônomo junto) e estimativa de instalações no primeiro ano.
3. **Prontidão:** o que mudou depois do teste e como você concluiu que o app estava pronto.

Responda com o que realmente aconteceu no teste. Segundo o Google, a análise
costuma levar até 7 dias, às vezes mais.

### B7. Produção

Com o acesso liberado: **Produção → Criar nova versão** → adicione a mesma versão do
teste fechado (ou uma nova) → países (Brasil, ou todos) → **Revisar e lançar**.

---

## C. App Store

### C1. Conta e acordos

- Apple Developer Program como pessoa física: US$ 99 por ano. O seu nome civil aparece
  como vendedor na App Store.
- Em App Store Connect → **Negócios**, aceite o acordo de licença mais recente. Apps
  gratuitos são distribuídos sob o acordo de licença do programa. O acordo de apps
  pagos só é preciso para vender o app ou ter compras dentro dele.

### C2. Assinatura no Xcode

1. Xcode → Ajustes → **Contas** → **+** → Apple ID → entre com a conta do programa.
2. Me avise. Eu abro o projeto, escolho o seu time em Signing & Capabilities (assinatura
   automática, identificador `com.raaquino.afinador`) e gero o `.ipa`:
   ```bash
   flutter build ipa --release
   ```
   O arquivo sai em `build/ios/ipa/`.

### C3. Status de comerciante na UE (Digital Services Act)

A Apple exige que **toda conta declare** se é ou não comerciante ("trader") para a lei
da União Europeia, mesmo quem não distribui na UE.

- Se declarar que é comerciante: endereço, telefone e e-mail ficam **públicos** na
  página do app nos países da UE.
- Se não distribuir na UE, você não atua como comerciante na App Store.

Essa avaliação é jurídica e é sua. Para um app gratuito, sem anúncios e sem vendas,
muitos desenvolvedores pessoa física se declaram não comerciantes. Se tiver dúvida,
uma saída é tirar os países da UE da disponibilidade (C6).

### C4. Criar o app

App Store Connect → **Apps → + → Novo app**:

- Plataforma: iOS
- Nome: `Afinador de Violão e Cordas`
- Idioma principal: Português (Brasil)
- ID do pacote: `com.raaquino.afinador`. Se não aparecer na lista, registre em
  developer.apple.com → Certificates, Identifiers & Profiles → Identifiers. Com
  assinatura automática, o Xcode costuma registrar sozinho no primeiro build.
- SKU: `afinador-001` (é interno, ninguém vê)
- Acesso de usuários: Acesso total → **Criar**.

### C5. Enviar o build e testar no TestFlight

1. Abra o app **Transporter** (Mac App Store), entre com a conta e arraste o `.ipa` →
   **Entregar**. Outra opção é enviar pelo Xcode.
2. Em alguns minutos o build aparece em App Store Connect → **TestFlight**. A pergunta de
   criptografia não aparece: o app já declara no Info.plist que não usa criptografia
   (`ITSAppUsesNonExemptEncryption = NO`).
3. Adicione-se como **testador interno** (até 100 pessoas da equipe; não passa pela
   revisão da Apple), instale o **TestFlight** no iPhone e faça os testes da seção 0.

### C6. Página do app na App Store

Na versão 1.0, preencha:

- **Capturas:** iPhone (tela de 6,3", Dynamic Island média): as 5 de
  `capturas/iPhone_17_Pro/`. iPad 13": as 5 de `capturas/iPad_Pro_13inch_M5/`.
  A Apple reduz para os outros tamanhos.
- **Texto promocional, descrição, palavras-chave:** de `textos_lojas.md` e `descricao_completa.txt`.
- **URL de suporte:** https://raaquino7.github.io/bancada-afinador/
- **Build:** escolha o build enviado no C5.
- **Copyright:** `2026 Rafael Aquino dos Santos` (ou o nome que preferir).
- **Notas para a revisão** (sugestão): "O app é um afinador e metrônomo. O microfone é
  usado só para detectar a nota no aparelho; nada é gravado ou enviado. Para testar, toque
  em 'Ligar microfone' e toque ou cante uma nota perto do aparelho. Não há login."

Em **Informações do app**:

- Subtítulo: `Metrônomo, guitarra e ukulele`
- Categoria principal: **Música**. Secundária: **Utilidades**.
- **Classificação etária:** responda ao questionário (todas as respostas "não"/"nenhum").
  O esperado é **4+**.
- URL da política de privacidade: https://raaquino7.github.io/bancada-afinador/privacidade.html

Em **Privacidade do app**: "Não, não coletamos dados deste app". A Apple define
coletar como transmitir para fora do aparelho, e o que é processado só no aparelho
não conta.

Em **Preços e disponibilidade**: Preço **Gratuito**; países: todos, ou só o Brasil, ou
todos menos a UE (veja C3).

### C7. Enviar para revisão

**Adicionar para revisão → Enviar para revisão.** Segundo a Apple, metade dos envios é
analisada em menos de 24 horas e 90% em menos de 48 horas. Escolha se a versão sai
automaticamente depois de aprovada ou quando você mandar.

---

## D. Versões seguintes

1. Aumente a versão em `pubspec.yaml`. Exemplo: `version: 1.0.1+2`. O número depois do
   `+` precisa sempre subir, em cada envio para cada loja.
2. Gere os pacotes:
   ```bash
   flutter build appbundle --release
   ```
   ```bash
   flutter build ipa --release
   ```
3. Google Play: crie uma versão nova na faixa (teste ou produção) e envie o `.aab`.
   App Store: envie o `.ipa` pelo Transporter, crie a nova versão em App Store Connect,
   preencha "Novidades desta versão" (obrigatório a partir da segunda versão) e envie
   para revisão.
4. Se gerar os ícones de novo (`dart run flutter_launcher_icons`), desfaça a mudança que
   o gerador faz em `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` no
   projeto do Xcode (deve continuar `YES`).
5. Capturas novas: `tool/captura.sh` (modo de captura, só em debug) e depois
   `swift tool/sem_alfa.swift` e `python3 loja/conferir_capturas.py`.
