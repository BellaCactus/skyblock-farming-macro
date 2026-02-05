#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Event"
SetKeyDelay 0, 0
SetTitleMatchMode 2
#UseHook True

; =========================
; DEFAULT CONFIG
; =========================
global cfg := Map(
    "StartKey", "F10"
  , "PauseKey", "F7"
  , "StopKey",  "F8"

  , "MoveLeft",  "a"
  , "MoveRight", "d"

  , "AttackKey", "LButton"
  , "HoldAttack", 1
  , "AttackKeepaliveMs", 700

  , "LaneMinutes", 2.0
  , "BetweenSeconds", 3.0
  , "LastLaneMinutes", 2.0
  , "Lanes", 5

  , "Loop", 1
  , "RespawnSeconds", 5.0

  , "LaneJitterMs", 400
  , "BetweenJitterMs", 300

  , "StartupDelayMs", 250
  , "DebugHUD", 0
)

; =========================
; RUN STATE
; =========================
global isRunning := false
global isPaused := false
global abort := false

global laneIndex := 1
global dir := 1
global phase := "idle"

global laneMsLeft := 0
global betweenMsLeft := 0
global respawnMsLeft := 0

global currentLaneTotalMs := 0
global currentBetweenTotalMs := 0
global currentRespawnTotalMs := 0

global lastTick := 0

; attack state
global attackHeld := false
global lastAttackKeepalive := 0

; movement state (IMPORTANT FIX)
global currentMoveDir := 0   ; 1=right, -1=left, 0=none

; HUD
global hudGui := 0
global hudText := 0

; =========================
; HELPERS
; =========================
MinToMs(min) => Round(min * 60 * 1000)
SecToMs(sec) => Round(sec * 1000)

Clamp(n, lo, hi) {
    if n < lo
        return lo
    if n > hi
        return hi
    return n
}

NormalizeHotkeyText(t) {
    t := Trim(t)
    t := StrReplace(t, " ", "")
    return t
}

PickJitter(maxAbsMs) {
    maxAbsMs := Abs(Integer(maxAbsMs))
    if maxAbsMs <= 0
        return 0
    return Random(-maxAbsMs, maxAbsMs)
}

SendKeyDown(k) => Send("{Blind}{" k " down}")
SendKeyUp(k)   => Send("{Blind}{" k " up}")

ReleaseMovementKeys() {
    global cfg, currentMoveDir
    SendKeyUp(cfg["MoveLeft"])
    SendKeyUp(cfg["MoveRight"])
    currentMoveDir := 0
}

ReleaseAttackKey() {
    global cfg, attackHeld
    SendKeyUp(cfg["AttackKey"])
    attackHeld := false
}

StopAllKeys() {
    ReleaseMovementKeys()
    ReleaseAttackKey()
}

ResetPlan() {
    global laneIndex, dir, phase
    global laneMsLeft, betweenMsLeft, respawnMsLeft
    global currentLaneTotalMs, currentBetweenTotalMs, currentRespawnTotalMs
    global lastTick
    global attackHeld, lastAttackKeepalive
    global currentMoveDir

    laneIndex := 1
    dir := 1
    phase := "idle"

    laneMsLeft := 0
    betweenMsLeft := 0
    respawnMsLeft := 0

    currentLaneTotalMs := 0
    currentBetweenTotalMs := 0
    currentRespawnTotalMs := 0

    lastTick := 0

    attackHeld := false
    lastAttackKeepalive := 0
    currentMoveDir := 0
}

; =========================
; MOVEMENT (IMPORTANT FIX)
; only change keys when direction changes
; =========================
SetMoveDir(newDir) {
    global cfg, currentMoveDir

    if newDir = currentMoveDir
        return

    ; release any old direction first
    if currentMoveDir = 1
        SendKeyUp(cfg["MoveRight"])
    else if currentMoveDir = -1
        SendKeyUp(cfg["MoveLeft"])

    currentMoveDir := newDir

    ; press the new direction once
    if newDir = 1
        SendKeyDown(cfg["MoveRight"])
    else if newDir = -1
        SendKeyDown(cfg["MoveLeft"])
    else {
        ; 0 = none
        SendKeyUp(cfg["MoveLeft"])
        SendKeyUp(cfg["MoveRight"])
    }
}

; =========================
; HUD (optional)
; =========================
InitHUD() {
    global hudGui, hudText
    if hudGui
        return
    hudGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    hudGui.BackColor := "000000"
    hudGui.SetFont("s10 cFFFFFF", "Segoe UI")
    hudText := hudGui.AddText("w420", "")
    WinSetTransparent(180, hudGui.Hwnd)
    hudGui.Show("x20 y60 NoActivate")
}

SetHUD(msg := "") {
    global cfg, hudGui, hudText
    if !cfg["DebugHUD"] {
        if hudGui
            hudGui.Hide()
        return
    }
    InitHUD()
    hudText.Value := msg
}

; =========================
; ATTACK HOLD (WITH KEEPALIVE)
; =========================
AttackTick(nowMs) {
    global cfg, attackHeld, lastAttackKeepalive

    if !cfg["HoldAttack"] {
        if attackHeld
            ReleaseAttackKey()
        return
    }

    if !attackHeld {
        SendKeyDown(cfg["AttackKey"])
        attackHeld := true
        lastAttackKeepalive := nowMs
        return
    }

    if cfg["AttackKeepaliveMs"] > 0 && (nowMs - lastAttackKeepalive) >= cfg["AttackKeepaliveMs"] {
        SendKeyDown(cfg["AttackKey"])
        lastAttackKeepalive := nowMs
    }
}

; =========================
; CONFIG GUI (tabs)
; =========================
ShowConfigGui() {
    global cfg

    g := Gui("+AlwaysOnTop +Resize", "lane macro config")
    g.SetFont("s10")

    tabs := g.AddTab3("w520 h620", ["basic", "misc"])

    tabs.UseTab("basic")
    g.AddText(, "hotkeys (examples: f10, f7, xbutton1, ^!p)")
    g.AddText("w180", "start/resume:")
    g.AddEdit("w260 vStartKey", cfg["StartKey"])
    g.AddText("w180", "pause/unpause:")
    g.AddEdit("w260 vPauseKey", cfg["PauseKey"])
    g.AddText("w180", "stop/reset:")
    g.AddEdit("w260 vStopKey", cfg["StopKey"])

    g.AddText("xm y+12", "movement keys")
    g.AddText("w180", "move left:")
    g.AddEdit("w260 vMoveLeft", cfg["MoveLeft"])
    g.AddText("w180", "move right:")
    g.AddEdit("w260 vMoveRight", cfg["MoveRight"])

    g.AddText("xm y+12", "attack/break")
    g.AddText("w180", "attack key:")
    g.AddEdit("w260 vAttackKey", cfg["AttackKey"])
    holdChk := g.AddCheckbox("vHoldAttack", "hold attack while moving")
    holdChk.Value := cfg["HoldAttack"]
    g.AddText("w180", "attack keepalive (ms, 0=off):")
    g.AddEdit("w260 vAttackKeepaliveMs", cfg["AttackKeepaliveMs"])

    g.AddText("xm y+12", "timings")
    g.AddText("w180", "lane minutes:")
    g.AddEdit("w260 vLaneMinutes", cfg["LaneMinutes"])
    g.AddText("w180", "between seconds:")
    g.AddEdit("w260 vBetweenSeconds", cfg["BetweenSeconds"])
    g.AddText("w180", "last lane minutes:")
    g.AddEdit("w260 vLastLaneMinutes", cfg["LastLaneMinutes"])
    g.AddText("w180", "number of lanes:")
    g.AddEdit("w260 vLanes", cfg["Lanes"])

    g.AddText("xm y+12", "loop + respawn")
    loopChk := g.AddCheckbox("vLoop", "loop forever")
    loopChk.Value := cfg["Loop"]
    g.AddText("w180", "respawn seconds:")
    g.AddEdit("w260 vRespawnSeconds", cfg["RespawnSeconds"])

    tabs.UseTab("misc")
    g.AddText(, "randomness (small jitter)")
    g.AddText("w180", "lane jitter ms:")
    g.AddEdit("w260 vLaneJitterMs", cfg["LaneJitterMs"])
    g.AddText("w180", "between jitter ms:")
    g.AddEdit("w260 vBetweenJitterMs", cfg["BetweenJitterMs"])

    g.AddText("xm y+12", "misc")
    g.AddText("w180", "startup grace (ms):")
    g.AddEdit("w260 vStartupDelayMs", cfg["StartupDelayMs"])
    dbgChk := g.AddCheckbox("vDebugHUD", "show click-through hud")
    dbgChk.Value := cfg["DebugHUD"]

    tabs.UseTab()

    btnRun := g.AddButton("xm y+14 w160 Default", "save + run")
    btnCancel := g.AddButton("x+10 w160", "cancel")

    btnRun.OnEvent("Click", (*) => (
        g.Submit()
      , ApplyConfigFromGui(g)
      , g.Destroy()
      , SetupHotkeys()
      , SetHUD("saved. start: " cfg["StartKey"] " | pause: " cfg["PauseKey"] " | stop: " cfg["StopKey"])
    ))
    btnCancel.OnEvent("Click", (*) => ExitApp())
    g.OnEvent("Close", (*) => ExitApp())

    g.Show("w540 h720")
}

ApplyConfigFromGui(g) {
    global cfg

    cfg["StartKey"] := NormalizeHotkeyText(g["StartKey"].Value)
    cfg["PauseKey"] := NormalizeHotkeyText(g["PauseKey"].Value)
    cfg["StopKey"]  := NormalizeHotkeyText(g["StopKey"].Value)

    cfg["MoveLeft"]  := NormalizeHotkeyText(g["MoveLeft"].Value)
    cfg["MoveRight"] := NormalizeHotkeyText(g["MoveRight"].Value)

    cfg["AttackKey"] := NormalizeHotkeyText(g["AttackKey"].Value)
    cfg["HoldAttack"] := g["HoldAttack"].Value ? 1 : 0
    cfg["AttackKeepaliveMs"] := Clamp(Integer(g["AttackKeepaliveMs"].Value), 0, 5000)

    cfg["LaneMinutes"]     := Clamp(Number(g["LaneMinutes"].Value), 0.05, 60)
    cfg["BetweenSeconds"]  := Clamp(Number(g["BetweenSeconds"].Value), 0, 30)
    cfg["LastLaneMinutes"] := Clamp(Number(g["LastLaneMinutes"].Value), 0.05, 60)
    cfg["Lanes"]           := Clamp(Integer(g["Lanes"].Value), 1, 50)

    cfg["Loop"]           := g["Loop"].Value ? 1 : 0
    cfg["RespawnSeconds"] := Clamp(Number(g["RespawnSeconds"].Value), 0, 30)

    cfg["LaneJitterMs"]    := Clamp(Integer(g["LaneJitterMs"].Value), 0, 2000)
    cfg["BetweenJitterMs"] := Clamp(Integer(g["BetweenJitterMs"].Value), 0, 2000)

    cfg["StartupDelayMs"] := Clamp(Integer(g["StartupDelayMs"].Value), 0, 5000)
    cfg["DebugHUD"]       := g["DebugHUD"].Value ? 1 : 0

    StopAndReset(true)
}

; =========================
; HOTKEYS
; =========================
SetupHotkeys() {
    global cfg
    Hotkey(cfg["StartKey"], (*) => StartOrResume(), "On")
    Hotkey(cfg["PauseKey"], (*) => TogglePause(), "On")
    Hotkey(cfg["StopKey"],  (*) => StopAndReset(), "On")
}

StartOrResume() {
    global isRunning, isPaused, abort, phase, cfg, lastTick
    if !isRunning {
        abort := false
        isPaused := false
        isRunning := true

        Sleep(cfg["StartupDelayMs"])

        if phase = "idle"
            phase := "move"

        lastTick := A_TickCount
        SetTimer(MainLoop, 30)
        SetTimer(UpdateHudLoop, 200)
    } else {
        isPaused := false
    }
}

TogglePause() {
    global isRunning, isPaused
    if !isRunning
        return
    isPaused := !isPaused
    if isPaused
        StopAllKeys()
}

StopAndReset(silent := false) {
    global isRunning, isPaused, abort, phase
    abort := true
    isPaused := false
    isRunning := false
    phase := "idle"

    SetTimer(MainLoop, 0)
    SetTimer(UpdateHudLoop, 0)

    StopAllKeys()
    ResetPlan()

    if !silent
        SetHUD("stopped + reset")
}

UpdateHudLoop() {
    global cfg, isRunning, isPaused, phase, laneIndex, dir
    global laneMsLeft, betweenMsLeft, respawnMsLeft

    if !cfg["DebugHUD"] {
        SetHUD("")
        return
    }

    if !isRunning {
        SetHUD("ready. start: " cfg["StartKey"])
        return
    }

    d := (dir = 1) ? "right" : "left"
    leftSec := 0.0
    if phase = "move"
        leftSec := laneMsLeft / 1000.0
    else if phase = "between"
        leftSec := betweenMsLeft / 1000.0
    else if phase = "respawn"
        leftSec := respawnMsLeft / 1000.0

    status := isPaused ? "paused" : "running"
    SetHUD("lane " laneIndex "/" cfg["Lanes"] " | " phase " | " d " | " Format("{:.1f}s", leftSec) " | " status)
}

; =========================
; MAIN LOOP (REAL TIME)
; =========================
MainLoop() {
    global cfg
    global isRunning, isPaused, abort
    global laneIndex, dir, phase
    global laneMsLeft, betweenMsLeft, respawnMsLeft
    global currentLaneTotalMs, currentBetweenTotalMs, currentRespawnTotalMs
    global lastTick

    if abort || !isRunning {
        SetTimer(MainLoop, 0)
        return
    }
    if isPaused
        return

    now := A_TickCount
    dt := now - lastTick
    if dt < 1
        dt := 1
    lastTick := now

    if phase = "move" {
        if currentLaneTotalMs <= 0 {
            base := (laneIndex = cfg["Lanes"]) ? MinToMs(cfg["LastLaneMinutes"]) : MinToMs(cfg["LaneMinutes"])
            jitter := PickJitter(cfg["LaneJitterMs"])
            currentLaneTotalMs := Max(50, base + jitter)
            laneMsLeft := currentLaneTotalMs

            ; IMPORTANT: set direction ONCE per lane
            SetMoveDir(dir)
        }

        AttackTick(now)

        laneMsLeft -= dt
        if laneMsLeft <= 0 {
            StopAllKeys()

            if laneIndex >= cfg["Lanes"] {
                if cfg["Loop"] {
                    currentRespawnTotalMs := Max(0, SecToMs(cfg["RespawnSeconds"]))
                    respawnMsLeft := currentRespawnTotalMs
                    phase := "respawn"

                    ; during respawn you said holding right is fine
                    SetMoveDir(1)
                } else {
                    isRunning := false
                    phase := "idle"
                    SetTimer(MainLoop, 0)
                    SetTimer(UpdateHudLoop, 0)
                    StopAllKeys()
                    ResetPlan()
                }
                return
            }

            currentBetweenTotalMs := 0
            betweenMsLeft := 0
            phase := "between"
            SetMoveDir(0)
        }
        return
    }

    if phase = "between" {
        if currentBetweenTotalMs <= 0 {
            base := SecToMs(cfg["BetweenSeconds"])
            jitter := PickJitter(cfg["BetweenJitterMs"])
            currentBetweenTotalMs := Max(0, base + jitter)
            betweenMsLeft := currentBetweenTotalMs
            SetMoveDir(0)
        }

        betweenMsLeft -= dt
        if betweenMsLeft <= 0 {
            laneIndex += 1
            dir := -dir
            currentLaneTotalMs := 0
            laneMsLeft := 0
            phase := "move"
        }
        return
    }

    if phase = "respawn" {
        respawnMsLeft -= dt
        if respawnMsLeft <= 0 {
            StopAllKeys()
            laneIndex := 1
            dir := 1
            currentLaneTotalMs := 0
            laneMsLeft := 0
            phase := "move"
        }
        return
    }
}

; =========================
; STARTUP
; =========================
ResetPlan()
ShowConfigGui()
