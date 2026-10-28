# Roadmap M-PLAY PS4

## Phase 0 — Bootstrap
- [x] Native C++ entry point
- [x] About/creator strings
- [x] Package metadata template and icon
- [x] GitHub Actions workflow draft
- [ ] First successful CI build confirmed
- [ ] Test launch on the target PS4

## Phase 1 — Real UI
- [ ] Integrate an OpenOrbis-compatible SDL2 port or another verified renderer
- [ ] 1920×1080 layout, focus states and readable TV typography
- [ ] DualShock 4 input mapping and controller disconnect handling
- [ ] In-app clock, after confirming a suitable system API
- [ ] Click/type sound settings

## Phase 2 — Local media
- [ ] File browser scoped to verified, accessible mount points
- [ ] Safe copy/paste, rename and delete with confirmations
- [ ] USB volume detection and error handling
- [ ] MP3 and MP4 playback after selecting and validating decoder libraries

## Phase 3 — IPTV
- [ ] M3U/M3U8 parser and local playlist import
- [ ] HTTP(S) playlist loading with timeouts and error reporting
- [ ] Channel groups, favourites and recent channels
- [ ] Stream playback only after networking and decoder compatibility tests
- [ ] Optional XMLTV EPG

## Phase 4 — Settings and release quality
- [ ] Persistent configuration
- [ ] Reset-to-defaults with confirmation
- [ ] About page and credits
- [ ] Test matrix across supported firmware / homebrew environments
- [ ] PKG validation and release notes
