"""Confere os textos das lojas contra os limites oficiais (conferidos em 15/11/2026)."""
import pathlib
import re
import sys

aqui = pathlib.Path(__file__).parent
md = (aqui / "textos_lojas.md").read_text(encoding="utf-8")
descricao = (aqui / "descricao_completa.txt").read_text(encoding="utf-8").strip()


def campo(secao, nome):
    bloco = md.split(f"## {secao}")[1].split("\n## ")[0]
    linha = re.search(rf"^\| {re.escape(nome)} \| (.+?) \|", bloco, re.M)
    return linha.group(1)


palavras = re.search(r"```\n(.+?)\n```", md, re.S).group(1)

checagens = [
    ("Play: nome", campo("Google Play", "Nome do app"), 30),
    ("Play: descrição curta", campo("Google Play", "Descrição curta"), 80),
    ("Play/App Store: descrição", descricao, 4000),
    ("App Store: nome", campo("App Store", "Nome"), 30),
    ("App Store: subtítulo", campo("App Store", "Subtítulo"), 30),
    ("App Store: texto promocional", campo("App Store", "Texto promocional"), 170),
]

ok = True
for nome, texto, limite in checagens:
    n = len(texto)
    marca = "ok " if n <= limite else "PASSOU"
    ok &= n <= limite
    print(f"{marca} {nome}: {n}/{limite}")

n_bytes = len(palavras.encode("utf-8"))
print(f"{'ok ' if n_bytes <= 100 else 'PASSOU'} App Store: palavras-chave: {n_bytes}/100 bytes ({len(palavras)} caracteres)")
ok &= n_bytes <= 100
if " ," in palavras or ", " in palavras:
    print("PASSOU palavras-chave com espaço depois da vírgula")
    ok = False

usadas = set(re.findall(r"\w+", (campo("App Store", "Nome") + " " + campo("App Store", "Subtítulo")).lower()))
repetidas = [p for p in palavras.split(",") if p in usadas]
if repetidas:
    print("aviso: palavras-chave repetem o nome/subtítulo:", repetidas)

sys.exit(0 if ok else 1)
