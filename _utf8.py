import sys
MOJIBAKE = [
    ("\u00c2\u00b7", "\u00b7"),
    ("\u00e2\u20ac\u201d", "\u2014"),
    ("\u00e2\u20ac\u201c", "\u2013"),
    ("\u00e2\u20ac\u2122", "'"),
    ("\u00e2\u20ac\u02dc", "'"),
]

def fix(path):
    raw = open(path, "rb").read()
    if len(raw) >= 2 and raw[1] == 0 and raw[0] != 0:
        text = raw.decode("utf-16-le")
        open(path, "wb").write(text.encode("utf-8"))
        print(f"[utf16->utf8] {path}")
    text = open(path, "rb").read().decode("utf-8")
    fixed = text
    for bad, good in MOJIBAKE:
        fixed = fixed.replace(bad, good)
    if fixed != text:
        open(path, "wb").write(fixed.encode("utf-8"))
        print(f"[fixed] {path}")
    else:
        print(f"[ok] {path}")

for p in sys.argv[1:]:
    fix(p)
