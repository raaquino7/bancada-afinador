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
    if [[ $2 == emulator-* ]]; then
      # Modo demonstração do Android: relógio 9:41, bateria cheia, sem notificações.
      adb=${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}/platform-tools/adb
      dev=$2
      $adb -s "$dev" shell settings put global sysui_demo_allowed 1
      demo() { $adb -s "$dev" shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
      demo enter
      demo clock -e hhmm 0941
      demo battery -e level 100 -e plugged false
      demo network -e wifi show -e level 4 -e mobile hide
      demo notifications -e visible false
    fi
    xcrun simctl status_bar "$2" override --time 9:41 --batteryState discharging --batteryLevel 100 \
      --wifiBars 3 --cellularMode active --cellularBars 4 2>/dev/null || true
    pkill -f "flutter_tools.snapshot run" || true
    flutter run -d "$2" --dart-define=CAPTURA_HZ="$3" > "$LOG" 2>&1 &
    for i in {1..90}; do grep -q "Flutter run key commands" "$LOG" && exit 0; sleep 2; done
    tail -20 "$LOG"; exit 1
    ;;
  foto)
    if [[ $2 == emulator-* ]]; then
      adb=${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}/platform-tools/adb
      mkdir -p loja/capturas/Android_1080x1920
      $adb -s "$2" exec-out screencap -p > "loja/capturas/Android_1080x1920/$3.png"
      sips -g pixelWidth -g pixelHeight "loja/capturas/Android_1080x1920/$3.png" | tail -2 | tr '\n' ' '; echo
      exit 0
    fi
    nome=$(xcrun simctl list devices | grep "$2" | sed -E 's/^ *(.*) \(.*\) \(.*$/\1/' | tr ' ' '_' | tr -d '()-')
    mkdir -p "loja/capturas/$nome"
    xcrun simctl io "$2" screenshot "loja/capturas/$nome/$3.png" >/dev/null 2>&1
    sips -g pixelWidth -g pixelHeight "loja/capturas/$nome/$3.png" | tail -2 | tr '\n' ' '; echo
    ;;
  parar)
    pkill -f "flutter_tools.snapshot run" || true
    ;;
esac
