<div align="center">

# ♡ skyblock farming macro (ahk v2)

simple **AutoHotkey v2** farming macro for **hypixel skyblock**.  
**static script only** (no installer), just **.ahk**.

![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2-2b2b2b?style=for-the-badge)
![Windows](https://img.shields.io/badge/Windows-only-0b0b0b?style=for-the-badge)
![Macro](https://img.shields.io/badge/type-farming_macro-ff78c8?style=for-the-badge)

</div>

---

## what is this?

this macro alternates **A / D** movement on a timer (lane swapping)  
and can optionally **hold attack** while moving.

**main file:** `farming-macro.ahk`

---

## features

- startup **config gui** (hotkeys + timings)
- lane timer (minutes) + between-lane delay (seconds)
- optional **hold attack**
- optional **keepalive** taps (for setups that drop held clicks)
- optional **loop / respawn delay**
- optional **debug hud** overlay

---

## requirements

- **windows**
- **AutoHotkey v2.0+**

---

## quick start

1) install **AutoHotkey v2**  
2) run `farming-macro.ahk`  
3) set your keys + timings in the config window  
4) open minecraft and press your **start** key

---

## default hotkeys

- **start / resume:** `F10`  
- **pause / unpause:** `F7`  
- **stop + reset:** `F8`  

(change in the gui)

---

## how it works

- **move phase:** holds **A** or **D** for `lane minutes`  
- **between phase:** stops for `between seconds`, flips direction  
- if **loop** is on, it waits `respawn seconds` after the last lane, then restarts

---

## config notes

- **attack key** default: `LButton`
- **keepalive (ms):** if set, it re-sends “attack down” every N ms

---

## run locally / edit

open `farming-macro.ahk` in any text editor and change values.  
AutoHotkey v2 is required to run it.

---

## notes

- don’t run this unattended
- if it feels “stuttery”, increase between-lane delay slightly
- if held attack randomly stops, enable keepalive or raise its interval

---

## status

works for my setup, still getting tweaks over time. (:3)
