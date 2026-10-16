# VidStills architecture

VidStills is a single-window SwiftUI app for macOS 14+. It has no third-party dependencies and no Swift packages. This document is for anyone who wants to understand, change or extend it.

## Flow

```
idle  →  loaded  →  processing  →  complete
                        └→ cancelled → loaded
         any  →  error  →  idle
```

1. **Idle.** The drop well accepts any file whose type conforms to `movie`, `video` or `audiovisualContent` (MP4, MOV, M4V, HEVC, ProRes …). **Browse…** uses `NSOpenPanel`.
2. **Loaded.** `AVURLAsset` probes the file for resolution (with the track's `preferredTransform` applied), duration, nominal frame rate and an *estimated* frame count (`duration × fps`).
3. **Pick destination.** **Extract every frame…** opens a folder picker that starts in the video's own folder. Stills are written directly into the chosen folder, with no automatic `Stills/` subfolder, so several videos in one parent folder don't pile up `Stills/`, `Stills 2/`, `Stills 3/`.
4. **Processing.** `FrameExtractor` decodes the video sequentially and writes each frame as it arrives (see below). The progress bar is based on the estimated count. If a video delivers a few more frames than estimated, the total is raised so the bar never passes 100%.
5. **Complete.** Shows the real number of frames written and a **Reveal in Finder** button.
6. **Error.** One plain-English message and a **Try again** button.

Cancellation is cooperative: `Task.checkCancellation()` runs before every frame and calls `AVAssetReader.cancelReading()`. Frames already written stay on disk.

## Frame extraction

`Services/FrameExtractor.swift` is an `actor` that:

1. opens the first video track with `AVAssetReader` + `AVAssetReaderTrackOutput` (32BGRA pixel buffers);
2. loops over `copyNextSampleBuffer()` until the track ends;
3. converts each `CVPixelBuffer → CIImage`, applies the track's `preferredTransform` so portrait and rotated footage comes out upright, and renders to an sRGB `CGImage` with a single reused `CIContext`;
4. writes the image with `CGImageDestination` (ImageIO).

### Why `AVAssetReader` and not `AVAssetImageGenerator`

`AVAssetImageGenerator` is designed for thumbnails: random-access seeks to particular times. Forcing it to grab every frame with zero time tolerance often fails with `AVError.decodeError` on modern codecs, especially HEVC screen recordings. `AVAssetReader` decodes the stream in order, the way the encoder wrote it, which is Apple's recommended approach for exhaustive frame extraction.

### Why JPEG and not PNG

A 1080p frame saved as JPEG at quality 0.9 is about 250 KB. As PNG it is 3–5 MB. Across an hour of 30 fps video, that's roughly 25 GB versus 300 GB or more. For natural video content, JPEG at 0.9 looks the same as PNG. PNG only earns its size for ML training data, frame-accurate VFX work or footage with transparency.

**Lossless output is a one-line change.** `FrameOutputFormat.png` is already implemented. In `State/AppState.swift`, pass a format to the extractor:

```swift
let written = try await extractor.extract(
    source: video.url,
    output: outputFolder,
    format: .png,                       // ← add this line
    expectedFrameCount: video.estimatedFrameCount
) { … }
```

You can also change the JPEG quality with `.jpeg(quality: 0.95)`. If you switch formats, update the "JPG" wording in `DropWellView`, `FileLoadedView` and the folder-picker message in `AppState`.

### File naming

`frame_0001.jpg`, `frame_0002.jpg`, … are zero-padded to the number of digits in the estimated total, so Finder and command-line tools sort them correctly.

## Source map

```
VidStills/
├── VidStillsApp.swift          @main; fixed 560×640 window with a hidden title bar
├── ContentView.swift           Owns AppState and shows the view for the current Phase
├── State/
│   └── AppState.swift          @MainActor ObservableObject, Phase enum, VideoFile, panels
├── Views/
│   ├── DropWellView.swift      Idle state and drop target
│   ├── FileLoadedView.swift    File details strip and the Extract button
│   ├── ProcessingView.swift    Progress bar and Cancel
│   ├── CompleteView.swift      Done and Reveal in Finder
│   └── ErrorBannerView.swift   Error message and Try again
├── Components/
│   ├── DesignTokens.swift      Colours, type, spacing, radii, window size
│   ├── BrandMark.swift         Stacked-frames logo and filmstrip drop-well glyph
│   ├── PrimaryButton.swift     Filled "flame" button
│   └── SecondaryButton.swift   Outlined button
├── Services/
│   └── FrameExtractor.swift    AVAssetReader → CIImage → JPEG/PNG
├── Assets.xcassets             AppIcon, AccentColor, BrandMarkDark
└── VidStills.entitlements      App Sandbox + user-selected read/write
```

## Sandbox and entitlements

The app is sandboxed and has only these entitlements:

- `com.apple.security.app-sandbox`
- `com.apple.security.files.user-selected.read-write`: it can read the video you drop or choose and write to the folder you pick, and nothing else
- `com.apple.security.files.bookmarks.app-scope`

There is no network entitlement. Hardened Runtime is enabled.

## Design tokens

| Token | Hex | Use |
|---|---|---|
| chamois | `#F0E5CC` | Window canvas |
| bone | `#F7F0DF` | Drop-well surface |
| ink | `#1A1815` | Primary text |
| mutedInk | `#5C564B` | Secondary text |
| flame | `#FF5236` | Accent and primary button |
| flameHover | `#E63E25` | Primary button hover |

4 pt spacing grid, 8 pt corner radius on the well, 12 pt on the window. Typography is the system font (SF Pro / SF Mono).

## App icon

The icon is a standard multi-size `mac` `.appiconset` (16 to 1024 px) made from `docs/branding/VidStills_Light.jpg`. A dark version of the mark (`docs/branding/VidStills_Dark.jpg`) is included in the asset catalog as the `BrandMarkDark` image set. The legacy macOS AppIcon format can't hold a dark variant. If you later move to an Icon Composer `.icon` file (macOS 26+), the artwork is ready to drop in.

## Scope (intentionally narrow)

- Every frame, at native resolution, with no range selection
- JPEG at quality 0.9 (PNG is a one-line change)
- Light theme only
- No preferences window
- No analytics, telemetry, network access or auto-update

Ideas that would fit without making the app complicated: a JPEG/PNG toggle, an "every Nth frame" option, a time range, and batch-processing several videos. Please open an issue before starting on any of them.
