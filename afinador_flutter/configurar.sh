#!/bin/bash
# Monta o projeto Flutter do "Afinador de Violão e Cordas" (com.raaquino.afinador).
# Uso, no Terminal do Mac:  bash configurar.sh
set -e
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter não encontrado. Instale em https://docs.flutter.dev/get-started/install e rode de novo."
  exit 1
fi

echo "==> Criando o projeto (iOS e Android)"
flutter create --org com.raaquino --project-name afinador --platforms ios,android .

echo "==> Copiando o código do app"
rm -rf lib test
cp -R src/lib lib
cp -R src/test test

echo "==> Instalando dependências"
flutter pub add record flutter_soloud shared_preferences

echo "==> Permissão de microfone e nome do app"
MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q RECORD_AUDIO "$MANIFEST"; then
  perl -0pi -e 's|(<manifest[^>]*>)|$1\n    <uses-permission android:name="android.permission.RECORD_AUDIO"/>|' "$MANIFEST"
fi
perl -pi -e 's/android:label="[^"]*"/android:label="Afinador"/' "$MANIFEST"
for GRADLE in android/app/build.gradle android/app/build.gradle.kts; do
  if [ -f "$GRADLE" ]; then
    perl -pi -e 's/minSdk = flutter\.minSdkVersion/minSdk = 24/; s/minSdkVersion flutter\.minSdkVersion/minSdkVersion 24/' "$GRADLE"
  fi
done
PLIST=ios/Runner/Info.plist
MIC_TEXT="O microfone é usado para ouvir a corda e mostrar se ela está afinada. O som não é gravado nem enviado."
plutil -replace NSMicrophoneUsageDescription -string "$MIC_TEXT" "$PLIST"
plutil -replace CFBundleDisplayName -string "Afinador" "$PLIST"

echo "==> Fontes da identidade visual"
mkdir -p assets/fonts
BASE=https://github.com/google/fonts/raw/main/ofl
if curl -fsSL "$BASE/bricolagegrotesque/BricolageGrotesque%5Bopsz%2Cwdth%2Cwght%5D.ttf" -o assets/fonts/Bricolage.ttf \
  && curl -fsSL "$BASE/instrumentsans/InstrumentSans%5Bwdth%2Cwght%5D.ttf" -o assets/fonts/InstrumentSans.ttf; then
  if ! grep -q "family: Bricolage" pubspec.yaml; then
    cat >> pubspec.yaml <<'YAML'

  fonts:
    - family: Bricolage
      fonts:
        - asset: assets/fonts/Bricolage.ttf
    - family: InstrumentSans
      fonts:
        - asset: assets/fonts/InstrumentSans.ttf
YAML
  fi
  echo "Fontes instaladas."
else
  rm -f assets/fonts/Bricolage.ttf assets/fonts/InstrumentSans.ttf
  echo "AVISO: não consegui baixar as fontes. O app funciona com a fonte do sistema."
fi

echo "==> Verificando o código"
flutter pub get
flutter analyze || echo "AVISO: o analisador apontou problemas. Copie a saída acima e envie ao Claude."
flutter test || echo "AVISO: algum teste falhou. Copie a saída acima e envie ao Claude."

echo
echo "Pronto. Conecte um celular e rode:  flutter run"
