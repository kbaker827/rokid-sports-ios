# Rokid Sports HUD

iOS app that fetches **live scores from ESPN** (free, no API key) and streams them to **Rokid AR glasses** via TCP :8093.

```
ESPN API (free) ──HTTPS──▶ iPhone (RokidSports) ──TCP :8093──▶ Rokid Glasses
```

## Supported leagues

| League | Sport |
|--------|-------|
| 🏈 NFL | Football |
| 🏀 NBA | Basketball |
| ⚾ MLB | Baseball |
| 🏒 NHL | Hockey |
| 🏈 NCAAF | College Football |
| 🏀 NCAAB | College Basketball |
| ⚽ MLS | Soccer |
| ⚽ Premier League | Soccer |
| 🏀 WNBA | Basketball |
| 🏈 CFL | Canadian Football |

## What's displayed on the glasses (TCP :8093)

```json
{"type":"scores","text":"NYG 17 – DAL 21 (Q3 8:45)  |  LAL 98 – GSW 102 (4th)","count":8}
{"type":"alert","text":"🏈 NYG 17 – DAL 24 (Q4 2:10)"}
```

## Display formats

| Format | Example |
|--------|---------|
| **Compact** | `NYG 17 – DAL 21 (Q3)  \|  LAL 98 – GSW 102 (4th)` |
| **Detailed** | Each game on its own line with emoji + full status |
| **Minimal** | `NYG 17-21 DAL  LAL 98-102 GSW` |

## Features

- Live scores prioritized — only live games shown when active, falls back to all games
- Score change alerts pushed immediately to glasses and shown in app
- Favorite teams filter — only see games featuring your teams
- Configurable refresh interval (10–120 s)
- Toggle scheduled / final games
- Pull-to-refresh
- League tab strip for quick filtering

## Setup

1. Open `RokidSports.xcodeproj` in Xcode 15+.
2. Set your team in Signing & Capabilities.
3. Build and run on iPhone (iOS 17+).
4. Grant local network permission when prompted.
5. Enable leagues and optionally add favorite teams in **Settings**.
6. Connect Rokid glasses to same Wi-Fi; point TCP client at `<phone-ip>:8093`.

## Data source

Uses the [ESPN undocumented public scoreboard API](https://gist.github.com/akeaswaran/b48b02f1c94f873c6655e7129910fc3b) — no API key required.

```
https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/scoreboard
```

## Requirements

- iOS 17.0+
- Xcode 15+
- Rokid AR glasses on the same Wi-Fi (optional)
