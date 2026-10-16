# VidStills v1.0.0

The first public release of VidStills: drag in a video and save every frame as a full-resolution JPG.

## Included

- Native SwiftUI macOS app source and Xcode project (macOS 14+, no dependencies)
- Drag-and-drop or Browse, file details (resolution, length, fps, frame count), folder picker, progress with Cancel, and Reveal in Finder
- Sequential `AVAssetReader` extraction that keeps native resolution and turns rotated footage upright, saving JPEG at quality 0.9
- Sandboxed, offline, no analytics
- MIT licence
- `VidStills.dmg`: signed with a Developer ID and notarised by Apple, so it opens without security warnings

## Fixes since the private version

- The info strip on the "Ready" screen no longer stretches to fill the window.
- The folder picker now says frames are saved as **JPG** (it wrongly said PNG).
- The progress bar can no longer pass 100% when a video holds more frames than estimated.

## Not included

- Any Apple signing certificate, private key, private path or development history in the source code. Signing is applied only to the downloadable build.
