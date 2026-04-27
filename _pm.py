import subprocess
from pathlib import Path
p = Path("lib/core/services/notifications/messaging_service.dart")
raw = subprocess.check_output(["git", "show", "HEAD:lib/core/services/notifications/messaging_service.dart"])
t = raw.decode("utf-8", errors="replace")
for a, b in [("\r\r\n", "\n"), ("\r\n", "\n"), ("\r", "\n")]:
    t = t.replace(a, b)
t = t.replace("_androidChannelId = 'toury_high_priority'", "_androidChannelId = 'rafiq_default'")
n = "import '../realtime/event_dedup_cache.dart';\n\nimport '../realtime/realtime_logger.dart';"
r = "import '../realtime/booking_realtime_event_bus.dart';\nimport '../realtime/event_dedup_cache.dart';\n\nimport '../realtime/realtime_logger.dart';"
assert n in t, n[:80]
t = t.replace(n, r, 1)
p.write_text(t, encoding="utf-8", newline="\n")
print("ok", p.stat().st_size)
