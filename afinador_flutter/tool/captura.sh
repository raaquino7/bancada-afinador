#!/bin/zsh
# Apoio às capturas de tela das lojas (etapa 10).
#   tool/captura.sh rodar <udid> <hz>   inicia o app em debug com o tom sintético
#   tool/captura.sh foto <udid> <nome>   salva loja/capturas/<pasta>/<nome>.png
#   tool/captura.sh parar               encerra o flutter run
set -e
cd "${0:A:h}/.."
LOG=${TMPDIR:-/tmp}/afinador_captura.log

case $1 in
  rodar)
    xcrun simctl status_bar "$2" override --time 9:41 --batteryState discharging --batteryLevel 100 \
      --wifiBars 3 --cellularMode active --cellularBars 4 2>/dev/null || true
    pkill -f "flutter_tools.snapshot run" || true
    flutter run -d "$2" --dart-define=CAPTURA_HZ="$3" > "$LOG" 2>&1 &
    for i in {1..90}; do grep -q "Flutter run key commands" "$LOG" && exit 0; sleep 2; done
    tail -20 "$LOG"; exit 1
    ;;
  foto)
    nome=$(xcrun simctl list devices | grep "$2" | sed -E 's/^ *(.*) \(.*\) \(.*$/\1/' | tr ' ' '_' | tr -d '()-')
    mkdir -p "loja/capturas/$nome"
    xcrun simctl io "$2" screenshot "loja/capturas/$nome/$3.png" >/dev/null 2>&1
    sips -g pixelWidth -g pixelHeight "loja/capturas/$nome/$3.png" | tail -2 | tr '\n' ' '; echo
    ;;
  parar)
    pkill -f "flutter_tools.snapshot run" || true
    ;;
esac
