"""Confere capturas e gráficos contra as regras oficiais (conferidas em 15/11/2026).

App Store: iPhone com Dynamic Island (tela média) 1179x2556 ou 1206x2622 e
iPad 13" 2064x2752 ou 2048x2732; de 1 a 10 por tamanho; sem canal alfa.
Google Play: de 2 a 8 capturas; lados entre 320 e 3840 px; o lado maior no
máximo o dobro do menor; PNG de 24 bits sem alfa ou JPEG. Gráfico de
destaque 1024x500 sem alfa.
"""
import pathlib
import subprocess
import sys

aqui = pathlib.Path(__file__).parent


def info(png):
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", "-g", "hasAlpha", str(png)],
                         capture_output=True, text=True).stdout
    campos = dict(l.strip().split(": ") for l in out.splitlines()[1:])
    return int(campos["pixelWidth"]), int(campos["pixelHeight"]), campos["hasAlpha"] == "yes"


ok = True


def checar(condicao, mensagem):
    global ok
    print(("ok  " if condicao else "ERRO") + " " + mensagem)
    ok &= condicao


grupos = {
    "iPhone_17_Pro": lambda w, h: (w, h) in {(1179, 2556), (1206, 2622)},
    "iPad_Pro_13inch_M5": lambda w, h: (w, h) in {(2064, 2752), (2048, 2732)},
    "Android_1080x1920": lambda w, h: 320 <= min(w, h) and max(w, h) <= 3840 and max(w, h) <= 2 * min(w, h),
}
for pasta, tamanho_valido in grupos.items():
    arquivos = sorted((aqui / "capturas" / pasta).glob("*.png"))
    limite = 8 if pasta.startswith("Android") else 10
    checar(1 <= len(arquivos) <= limite, f"{pasta}: {len(arquivos)} capturas (máximo {limite})")
    for f in arquivos:
        w, h, alfa = info(f)
        checar(tamanho_valido(w, h) and not alfa, f"{pasta}/{f.name}: {w}x{h}, alfa={'sim' if alfa else 'não'}")

w, h, alfa = info(aqui / "google_play_destaque_1024x500.png")
checar((w, h) == (1024, 500) and not alfa, f"gráfico de destaque: {w}x{h}, alfa={'sim' if alfa else 'não'}")
w, h, _ = info(aqui / "google_play_icone_512.png")
checar((w, h) == (512, 512), f"ícone do Google Play: {w}x{h}")

sys.exit(0 if ok else 1)
