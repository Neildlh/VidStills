# Security policy

## Supported versions

Security support applies to the current `main` branch only.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability or privacy problem. Use GitHub's private vulnerability reporting if it is enabled for this repository. If it isn't, contact the repository owner through GitHub before publishing any details.

Please include a clear reproduction, the affected commit, the impact, and any safe mitigation you found. Do not attach private media, certificates, provisioning profiles or keys.

## Scope

VidStills is a sandboxed, offline app with no network access. The most relevant areas are file handling (reading untrusted video files and writing into the user-chosen folder), sandbox entitlements, and anything that could make the app read or write outside the files the user explicitly selected.
