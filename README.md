# DrawOnGMaps2

A SwiftUI iOS app that embeds Google Maps, supports drawing overlays, and provides Street View with pegman controls. Maps SDK is pulled via Swift Package Manager (`https://github.com/googlemaps/ios-maps-sdk`).

## Quick Start
1. Copy `ios/DrawOnGMaps2/Config/Secrets.template.xcconfig` to `ios/DrawOnGMaps2/Config/Secrets.xcconfig`.
2. Set `GOOGLE_MAPS_API_KEY = <your key>` in `Secrets.xcconfig` **or** add an env var `GOOGLE_MAPS_API_KEY` in your Xcode scheme/CI. (Secrets.xcconfig is git-ignored.)
3. Open `ios/DrawOnGMaps2/DrawOnGMaps2.xcodeproj` in Xcode 13+ and run the `DrawOnGMaps2` scheme.
4. If packages don’t resolve automatically, run `File → Packages → Resolve`.

## How the Map Is Added
- **DrawOnGMaps2App.swift** — app entry; reads the key from Info.plist (`GMSApiKey`) or env, then calls `GMSServices.provideAPIKey(...)` before any map is shown.
- **MapBridge.swift** — `UIViewRepresentable` wrapper around `GMSMapView`; bridges camera/tap events and overlay drawing into SwiftUI.
- **MapContainerView.swift** — holds map state, connects controls to the bridge, manages drawings.
- **ContentView.swift** — top-level SwiftUI layout stacking the map, control panels, and Street View container.
- **StreetViewBridge.swift + StreetViewContainer.swift** — wraps `GMSPanoramaView` for Street View; syncs with pegman drops on the map.

## Feature Walkthrough
- Google Map display with camera controls and gesture handling.
- Drawing mode: user overlays rendered via `DrawingOverlayView` on top of `GMSMapView`.
- Street View: drop pegman to open `GMSPanoramaView`, with zoom/navigation controls.
- Location centering via `LocationManager` (CoreLocation) with permission prompt.
- Lightweight logging through `AgentDebugLogger` for lifecycle events.

## File-by-File Cheatsheet (iOS target)
- `DrawOnGMaps2App.swift` — App entry; API key injection; logging hook.
- `ContentView.swift` — Top-level scene composition (map + controls + Street View).
- `MapBridge.swift` — UIKit bridge for `GMSMapView`; gestures/camera/overlay plumbing.
- `MapContainerView.swift` — Map state and control wiring; manages drawings.
- `MapControlsView.swift` — Buttons/sliders for zoom, modes, draw tools.
- `DrawingOverlayView.swift` — Renders user-drawn polylines/polygons.
- `PegmanView.swift` — UI to drop into Street View; syncs with StreetViewBridge.
- `StreetViewBridge.swift` — Wraps `GMSPanoramaView`; loads panoramas.
- `StreetViewContainer.swift` — Combines Street View with controls/state.
- `StreetViewControlsView.swift`, `StreetViewZoomController.swift` — Street View UI widgets and zoom handling.
- `LocationManager.swift` — CoreLocation wrapper; provides current location to center the map.
- `DebounceHelpers.swift` — Throttles high-frequency events (camera moves, drags).
- `AgentDebugLogger.swift` — Simple logging helper for instrumentation.
- `Assets.xcassets` — App icons, accent colors, images.
- `Config/Secrets.template.xcconfig` — Template for `Secrets.xcconfig` (git-ignored) containing `GOOGLE_MAPS_API_KEY`.

## Key Management (no secrets in git)
- Actual keys live only in your local `ios/DrawOnGMaps2/Config/Secrets.xcconfig` (git-ignored) or in an Xcode/CI env var `GOOGLE_MAPS_API_KEY`.
- The project injects `GMSApiKey` into the generated Info.plist so `GMSServices` can read it at startup.

## Build/Run Tips
- If Xcode complains about Command Line Tools, point to full Xcode: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- For CI: `echo "GOOGLE_MAPS_API_KEY = $GOOGLE_MAPS_API_KEY" > ios/DrawOnGMaps2/Config/Secrets.xcconfig` then `xcodebuild -project ios/DrawOnGMaps2/DrawOnGMaps2.xcodeproj -scheme DrawOnGMaps2`.

## Troubleshooting
- Parse errors when opening the project: make sure you pulled latest `main` (pbxproj is fixed and compatible with older Xcode).
- Maps showing blank tiles: verify `GOOGLE_MAPS_API_KEY` is set and restricted correctly in Google Cloud.
- Packages missing: run `File → Packages → Resolve`.
