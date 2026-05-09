# UI routing and usage audit (pre-deletion)

Generated for safe refactors. **No routes or pages were removed** based on this document alone.

## Methodology

1. Routes are defined in `lib/core/router/app_router.dart` (GoRouter).
2. A page is **possibly unused** only if the Dart type is **never referenced** as an import/`AppRouter` navigation target and is not a **placeholder** intentionally reachable (deep links, notifications, manual URLs).
3. **Duplicate widgets** are identified by parallel patterns (empty/error/section headers), not only identical file names.

---

## 1. Duplicate / parallel UI (consolidation targets)

| Pattern | Examples | Recommended core API |
|--------|----------|----------------------|
| Empty state | `_buildEmptyState` in reports, ratings, invoices, service areas, chat, exams | `AppEmptyState` |
| Error + retry | `_ErrorState`, `_buildErrorState`, custom columns | `AppErrorState` |
| SnackBars | `ScaffoldMessenger` + raw `SnackBar` | `AppSnackbar` |
| Screen shell | Mixed `Scaffold` + hardcoded `BrandTokens.bgSoft` | `AppScaffold` + `Theme` / `AppColors` |
| Section title | `SectionHeader` (feature), `AppSectionHeader`, inline `Text` | `AppSectionHeader` |
| Loading | `CircularProgressIndicator` alone | `AppLoading` / `AppSpinner` |

---

## 2. “Dead routes” / placeholders (do not delete without product sign-off)

These routes **exist on purpose** for auth gating, onboarding, or notifications:

| Route / page | Risk if removed |
|--------------|-----------------|
| `/helper-onboarding`, `/waiting-approval`, `/account-inactive` | Helper lifecycle / admin approval flows |
| `/verify-google-code/:email`, Google verify placeholder | OAuth / future flows |
| `/reports` user placeholder | Push / SignalR targets |
| `/dev/realtime` | Diagnostics |
| Duplicate path aliases (e.g. `chatByConversation` vs `userChat`) | Deep links and legacy clients |

**Recommendation:** keep paths; optionally add `redirect` deprecation **after** telemetry proves zero hits.

---

## 3. Feature areas with **no** dedicated presentation layer (not “unused”)

| Path | Notes |
|------|--------|
| `lib/features/helper/features/helper_booking_tracking` | Domain + data + cubits only; UI lives under `helper_bookings` / tracking map screens. |

---

## 4. Unused *files* (requires per-file grep before delete)

Not fully enumerated in this pass. For each candidate `.dart` under `presentation/pages/`:

```text
rg -l "CandidatePage" lib/
```

If **only** the file itself matches, flag for removal **after** verifying no `go_router` builder string or dynamic import.

---

## 5. Safe deletions (current recommendation)

- **None** in this audit pass.  
- Remove dead privates / unused imports **inside** files while refactoring (low risk).  
- Route or page removal = **separate PR** with grep evidence + QA checklist.
