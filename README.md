DrawOnGMaps2 (iOS)
==================

SwiftUI app for Google Maps + Street View with freehand drawing, minimal controls, and tap-to-enter Street View.

⚠️ Setup
--------
- Add your Google Maps SDK key to `ios/DrawOnGMaps2/DrawOnGMaps2/DrawOnGMaps2App.swift` line 8 (`GMSServices.provideAPIKey(...)`).

Quick start
-----------
1) Open `ios/DrawOnGMaps2/DrawOnGMaps2.xcodeproj` in Xcode.  
2) Paste your API key as above.  
3) Build & run on a device/simulator with network + location permission.

Current UX (Mar 2026)
---------------------
- **Start at your location once** on launch; map/Street View won’t auto-recenter afterward unless you tap Locate.
- **Drawing (map)**: floating pen button (bottom-left) with color picker, live strokes anchored to map, undo/clear.
- **Drawing (Street View)**: same floating pen UI; undo/clear per mode.
- **Street View entry**: tap the blue Pegman button (bottom-right) to arm, then tap the map; auto-enters nearest panorama (150m radius) or shows a toast if none.
- **Locate Me**: system locate icon (bottom-right) recenters map only when tapped.
- **Angle toggle**: top-right circular icon toggles 3D tilt; traffic layer stays off.
- **Search**: top-left icon opens a compact sheet (auto-focus, clears previous text) with suggestions; works in both map and Street View and jumps there on select.
- **Street View pitch toggle**: top-right icon in Street View.

Change log (recent work)
------------------------
- Replaced top/bottom bars with floating icon controls for map and Street View.
- Added live map drawing via polylines, color picker auto-starts drawing, undo/clear per mode.
- Added tap-to-enter Street View mode with coverage check + toast on failure.
- Center-once-at-launch behavior; disabled repeated auto-recenter.
- Compact, auto-focused search sheet; clears previous query; suggestions scroll without covering the field.
- Removed traffic overlay when toggling 3D.
- Kept API key reference only in `DrawOnGMaps2App.swift`.

Known branches
--------------
- `codex/backup-20260328` (backup)
- `codex/restore-5b598b3` (restore)

Files of interest
-----------------
- App entry: `ios/DrawOnGMaps2/DrawOnGMaps2/DrawOnGMaps2App.swift`
- Main UI: `ios/DrawOnGMaps2/DrawOnGMaps2/ContentView.swift`
- Map wrapper: `ios/DrawOnGMaps2/DrawOnGMaps2/MapContainerView.swift`
- Street View wrapper: `ios/DrawOnGMaps2/DrawOnGMaps2/StreetViewContainer.swift`
- Drawing overlays: `ios/DrawOnGMaps2/DrawOnGMaps2/DrawingOverlayView.swift`, `MapPolylineDrawingOverlay.swift`
