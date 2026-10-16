# Contributing to VidStills

Thank you for wanting to improve VidStills. The app is deliberately small: it does one job and does it well. The best contributions keep it that way.

## Before opening an issue or pull request

- Use an issue for reproducible bugs and focused proposals. For anything bigger than a bug fix, open an issue first so we can agree on the approach.
- Explain the user-facing problem first. Include your macOS version, Mac model/chip and, if relevant, the video's format, resolution and frame rate.
- Never attach private videos, personal paths or Apple signing material. A short test clip that reproduces the issue is ideal.

## Pull requests

- Keep one user-visible change per pull request.
- Keep the app dependency-free, sandboxed and offline. Don't add network access, analytics or auto-update.
- Keep the one-window, no-settings feel. If an option is really needed, it should have a sensible default and stay out of the way.
- Use the existing design tokens in `Components/DesignTokens.swift` rather than new colours or sizes.
- Build and run the app, and extract at least one real video, before asking for review.

The technical starting point is [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
