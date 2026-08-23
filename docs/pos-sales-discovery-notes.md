# POS Sales Discovery Notes

## Scanner constraint

The repository currently depends on `mobile_scanner: ^7.2.0`. Its public widget attaches a `MobileScannerController` in `initState`, starts it when `autoStart` is enabled, and renders `CameraPreview(controller)` in the widget tree. The documented lifecycle requires pausing/stopping on app inactivity and restarting on resume. The plugin documentation does not expose a dedicated headless scanner service; a hidden mounted scanner widget can suppress the visible preview, but must be validated on real Android/iOS devices because zero-size/offstage platform views may affect camera analysis. The product decision is therefore: no camera preview in the sales UI; use a platform scanner adapter with an invisible mounted capture surface only if device validation proves reliable, otherwise implement a small native camera-analysis bridge.

The package supports Android and iOS, multiple barcode formats, back/front lens selection, detection speed controls, and camera permission configuration. The sales flow must debounce repeated detections, resolve a barcode through the product repository, emit an audible feedback event, and preserve keyboard-scanner input as a first-class fallback.

## PDF/share constraint

Qayd already uses the `pdf` package, Cairo fonts, branded PDF generators, `QaydHeaderConfig`, `share_pdf_bytes`, and `share_plus`. New POS documents should reuse these infrastructure pieces rather than create a separate visual system. The PDF must be generated from an immutable, canonical invoice snapshot containing lines, totals, payments, due amount, counterparty, status, and signature metadata. Sharing should use the existing platform share flow; the current share_plus documentation notes that files are supported on Android/iOS/Windows/Web/macOS but not Linux.

## Safety boundary

The current POS schema has `pos_invoices`, `pos_invoice_lines`, `pos_payments`, `pos_returns`, product barcodes, and stock movements. The prior opening-balance bridge is atomic, but no sales posting should be enabled until a separate sale document coordinator atomically persists invoice, stock outbound movement/weighted-average cost, accounting entries, and payment effects. Drafts must remain side-effect free. Posted documents must be immutable; returns and corrections must be new linked documents.

## Sources

- https://pub.dev/packages/mobile_scanner
- https://github.com/juliansteenbakker/mobile_scanner
- https://github.com/juliansteenbakker/mobile_scanner/issues/1119
- https://pub.dev/packages/pdf
- https://pub.dev/packages/share_plus
