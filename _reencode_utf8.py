"""Re-encode any UTF-16 LE files to UTF-8 (no BOM)."""

import sys
from pathlib import Path


def is_utf16_le(data: bytes) -> bool:
    if len(data) >= 2 and data[0] == 0xFF and data[1] == 0xFE:
        return True
    # heuristic: every other byte is null and first non-null is ASCII
    if len(data) >= 4 and data[1] == 0 and data[3] == 0 and 0x20 <= data[0] < 0x80:
        return True
    return False


def fix_file(p: Path) -> bool:
    raw = p.read_bytes()
    if not is_utf16_le(raw):
        return False
    if raw[:2] == b"\xff\xfe":
        text = raw[2:].decode("utf-16-le", errors="replace")
    else:
        text = raw.decode("utf-16-le", errors="replace")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    p.write_text(text, encoding="utf-8", newline="\n")
    return True


def main(argv):
    if len(argv) < 2:
        print("usage: _reencode_utf8.py <file_or_dir> [...]")
        return 1
    fixed = 0
    for arg in argv[1:]:
        path = Path(arg)
        if path.is_dir():
            files = [
                f for f in path.rglob("*")
                if f.is_file() and f.suffix in {".dart", ".md", ".json", ".yaml", ".yml", ".gradle", ".kts", ".pro"}
            ]
        else:
            files = [path]
        for f in files:
            try:
                if fix_file(f):
                    print(f"fixed: {f}")
                    fixed += 1
            except Exception as e:
                print(f"skip {f}: {e}")
    print(f"done. fixed {fixed} file(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
