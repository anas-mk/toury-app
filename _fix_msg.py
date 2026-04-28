import subprocess
from pathlib import Path
p = Path("lib/core/services/notifications/messaging_service.dart")
raw = subprocess.check_output(["git", "show", "HEAD:lib/core/services/notifications/messaging_service.dart"])
p.write_bytes(raw)
text = p.read_text(encoding="utf-8", errors="replace")
for a,b in [("\r\r\n","\n"),("\r\n","\n"),("\r","\n")]:
    text = text.replace(a,b)
text = text.replace("_androidChannelId = 'toury_default'", "_androidChannelId = 'rafiq_default'")
text = text.replace("_androidChannelName = 'Toury notifications'", "_androidChannelName = 'Rafiq notifications'")
p.write_text(text, encoding="utf-8", newline="\n")
print("ok", p.stat().st_size)