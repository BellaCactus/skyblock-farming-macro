# skyblock farming macro (ahk v2)

tiny lane-walker macro for farming that alternates **a/d** lanes and can **hold attack** while moving.
it opens a lil config window on launch so you can set timings + hotkeys.

> **note:** automation can get you muted/banned depending on server rules + how obvious it is. use at your own risk.

## features
- gui config on startup (hotkeys, timings, jitter, debug hud)
- lane timer + between-lane delay
- optional loop + respawn delay
- attack hold with keepalive taps (helps when some games stop “held click” from registering)

## requirements
- **windows**
- **AutoHotkey v2.0+** (the script has `#Requires AutoHotkey v2.0`)

## quick start
1. install **AutoHotkey v2** (not v1)
2. download this repo (green “code” button → download zip)
3. double-click `farming-macro.ahk`
4. in the config window, set your keys + timings
5. press your **start key** in-game

## default hotkeys
- **start / resume:** `F10`
- **pause / unpause:** `F7`
- **stop + reset:** `F8`

(you can change these in the gui)

## how it works (tldr)
- phase `move`: holds **a** or **d** for `lane minutes` (last lane uses `last lane minutes`)
- phase `between`: stops moving for `between seconds`, flips direction, goes again
- optional `loop forever`: after final lane, holds right during `respawn seconds`, then restarts

## config notes
- **attack key** default is `LButton`
- **hold attack while moving** toggles continuous attack
- **attack keepalive (ms)**: if > 0, re-sends “down” every N ms (some setups need this)

## debug hud
set **debug hud** on to show a small click-through overlay with:
lane / phase / direction / time left / running state.

## folder layout
- `farming-macro.ahk` - main script

## safety / etiquette
if you’re gonna use automation, at least:
- keep jitter on (small randomness)
- don’t brag about it
- don’t run it unattended

## credits
made by bella (:
