# Escanor releases

Escanor AI is the engineering operating system for AI-native teams: connect your stack and coding agents, then deploy, debug and recover in one place. Learn more at [www.escanor.in](https://www.escanor.in).

This repository holds **downloads only** (no source code). Every release here lists its files with their SHA-256 checksums.

## Download

The easiest way is the website, which always sends you to the newest file for your device:

| Device | Link |
| --- | --- |
| Android phone | [www.escanor.in/download/android](https://www.escanor.in/download/android) |
| Android phone, with phone control | [www.escanor.in/download/android-control](https://www.escanor.in/download/android-control) |
| Windows | [www.escanor.in/download/windows](https://www.escanor.in/download/windows) |
| Windows, from the Microsoft Store | [apps.microsoft.com/detail/9p4jcn4ss6s6](https://apps.microsoft.com/detail/9p4jcn4ss6s6) |
| macOS (Apple silicon) | [www.escanor.in/download/mac-arm](https://www.escanor.in/download/mac-arm) |
| macOS (Intel) | [www.escanor.in/download/mac-intel](https://www.escanor.in/download/mac-intel) |
| Linux (AppImage) | [www.escanor.in/download/linux](https://www.escanor.in/download/linux) |
| Linux (.deb) | [www.escanor.in/download/linux-deb](https://www.escanor.in/download/linux-deb) |

Or pick a version on the [Releases](https://github.com/escanorlabs-source/escanor-releases/releases) page. Tags: `vX.Y` is the Android app, `desktop-vX.Y.Z` is Escanor Desktop.

## Check your download

```sh
sha256sum <file>          # Linux
shasum -a 256 <file>      # macOS
certutil -hashfile <file> SHA256   # Windows
```

The result must match the SHA-256 line in the release notes.

## Help

Write to admin@escanor.in.
