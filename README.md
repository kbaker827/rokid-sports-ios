# Rokid Sports HUD


> **🔵 Connectivity Update — May 2025**
> The glasses connection has been migrated from **raw TCP sockets** to
> **Bluetooth via the Rokid AI glasses SDK** (`pod 'RokidSDK' ~> 1.10.2`).
> No Wi-Fi port forwarding is needed. See **SDK Setup** below.

iOS app that fetches **live scores from ESPN** (free, no API key) and streams them to **Rokid AR glasses** via Bluetooth/RokidSDK.

```
ESPN API (free) ──HTTPS──▶ iPhone (RokidSports) ──Bluetooth/RokidSDK──▶ Rokid Glasses
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

## What's displayed on the glasses

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

## SDK Setup

The glasses now connect over **Bluetooth via the Rokid AI glasses SDK** — no Wi-Fi port or TCP server needed.

The only thing left for each app is filling in the three credential constants (`kAppKey`, `kAppSecret`, `kAccessKey`) from [account.rokid.com/#/setting/prove](https://account.rokid.com/#/setting/prove), then running `pod install`.

1. **Get credentials** at <https://account.rokid.com/#/setting/prove> and paste them into the glasses Swift file:
   ```swift
   private let kAppKey    = "YOUR_APP_KEY"
   private let kAppSecret = "YOUR_APP_SECRET"
   private let kAccessKey = "YOUR_ACCESS_KEY"
   ```

2. **Install CocoaPods dependencies** from the repo root:
   ```bash
   pod install
   open *.xcworkspace   # always open the .xcworkspace, not .xcodeproj
   ```

3. *(Glasses now connect automatically over Bluetooth — no TCP port needed.)*

## Setup

1. Open `RokidSports.xcworkspace` in Xcode 15+ (after running `pod install`) 15+.
2. Set your team in Signing & Capabilities.
3. Build and run on iPhone (iOS 17+).
4. Grant local network permission when prompted.
5. Enable leagues and optionally add favorite teams in **Settings**.
6. *(Glasses now connect automatically over Bluetooth — no TCP port needed.)*

## Data source

Uses the [ESPN undocumented public scoreboard API](https://gist.github.com/akeaswaran/b48b02f1c94f873c6655e7129910fc3b) — no API key required.

```
https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/scoreboard
```

## Requirements

- iOS 17.0+
- Xcode 15+
- Rokid AI glasses (paired via Bluetooth — no Wi-Fi needed) (optional)
