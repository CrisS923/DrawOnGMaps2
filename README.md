## iOS setup

1. Copy `ios/DrawOnGMaps2/Config/Secrets.template.xcconfig` to `ios/DrawOnGMaps2/Config/Secrets.xcconfig` and set `GOOGLE_MAPS_API_KEY` to your Maps key. The secrets file is git-ignored.
2. Alternatively, set an environment variable `GOOGLE_MAPS_API_KEY` in your Xcode scheme or CI; the build will inject it into the generated Info.plist.
3. Build/run the `DrawOnGMaps2` scheme.
