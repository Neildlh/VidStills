# VidStills v1.0.0

The first public release of VidStills: drag in a video and save every frame as a full-resolution JPG.

## Included

- Native SwiftUI macOS app source and Xcode project (macOS 14+, no dependencies)
- Drag-and-drop or Browse, file details (resolution, length, fps, frame count), folder picker, progress with Cancel, and Reveal in Finder
- Sequential `AVAssetReader` extraction that keeps native resolution and turns rotated footage upright, saving JPEG at quality 0.9
- Sandboxed, offline, no analytics
- MIT licence

## Fixes since the private version

- The info strip on the "Ready" screen no longer stretches to fill the window.
- The folder picker now says frames are saved as **JPG** (it wrongly said PNG).
- The progress bar can no longer pass 100% when a video holds more frames than estimated.

## Not included

- A notarised installer. Any release build is ad-hoc signed, so macOS asks you to approve it once (see the README).
- Any Apple signing certificate, Team ID, private path or development history.
