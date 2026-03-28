DrawOnGMaps2 (iOS)
==================

SwiftUI app that lets you explore Google Maps and Street View, draw annotations on top, and jump between map and panorama modes.

Quick start
-----------
1. Open `ios/DrawOnGMaps2/DrawOnGMaps2/DrawOnGMaps2App.swift` and replace the placeholder string in `GMSServices.provideAPIKey("add your api key.")` with your Google Maps SDK key. This is the only place the key is needed in this snapshot.
2. Open `ios/DrawOnGMaps2/DrawOnGMaps2.xcodeproj` in Xcode (Google Maps and Street View SDKs are already referenced). 
3. Build and run on a simulator or device with network access.

Features
--------
- **Google Maps (satellite)** with pan/zoom, angle toggle, traffic/buildings enabled, and a “Locate Me” shortcut.
- **Street View**: open via Pegman drag-and-drop from the map or from search results; custom pinch-to-zoom and optional pitched “angle” view.
- **Drawing overlays** on both map and Street View with lock/unlock, clear, and color picker (yellow/blue/black/red/silver).
- **Search with autocomplete** (Apple MKLocalSearch): suggestions dropdown, open results on the map or directly in Street View, plus small Street View preview card.
- **Pegman overlay**: draggable entry to Street View at any map point; hides after drop.
- **Stateful controls**: toggle angled map view, toggle drawings, lock drawings, clear drawings.
- **Location handling**: request permission, use last known location, and cool-down to avoid spamming “Locate Me.”

Notes
-----
- The repo includes a backup branch `codex/backup-20260328` and a restore branch `codex/restore-5b598b3`; main remains untouched.
- If you previously kept keys in an external config, ensure you still set the runtime key in `DrawOnGMaps2App.swift` before shipping.
