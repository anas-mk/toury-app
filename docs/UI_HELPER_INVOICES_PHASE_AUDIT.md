# Helper invoices — routing, usage & safe deletion audit (phase)

## Routes

- /helper/invoices (name: helper-invoices) → InvoicesPage
- /helper/invoice-detail/:id (name: helper-invoice-detail) → InvoiceDetailPage  
- /helper/invoice-view/:id (name: helper-invoice-view) → InvoiceViewPage

WalletHubPage and EarningsPreviewCard navigate into these flows.

## Duplicate widget note

_StatusBadge vs _StatusPill overlap; defer shared core widget until user + helper invoice UIs aligned.

## Safe deletions

No page or route removal this phase.

## Contract

Presentation only — cubits/repos/APIs untouched; navigation compatible.
