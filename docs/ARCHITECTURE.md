# Architecture notes

Keep platform-dependent code behind narrow interfaces so the media/UI logic can be tested independently.

Suggested future modules:
- `ui/`: screens, layout, focus navigation, input actions
- `platform/`: controller, clock, filesystem mount discovery, network access
- `iptv/`: M3U parser, playlist model, EPG
- `player/`: decoder backend and playback state
- `settings/`: validated configuration and reset
- `storage/`: safe file operations with explicit confirmation

## Safety and reliability
- Never recursively delete a path without a confirmation screen.
- Normalize paths and reject traversal outside the selected mount.
- Treat playlist URLs and media metadata as untrusted input.
- Use timeouts and size limits when loading remote playlists.
- Do not silently overwrite files during copy operations.
- Avoid bundling third-party libraries until PS4 compatibility and license are checked.
