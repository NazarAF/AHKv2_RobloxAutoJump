#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode(2)
CoordMode("ToolTip", "Screen")

; ====== CONFIGURATION (edit only here) ======
global INTERVAL_MS         := 600000   ; Delay between jumps (600000 = 10 minutes)
global HOLD_SPACE_MS       := 80       ; How long the spacebar is held down
global FOCUS_DELAY_MS      := 150      ; Wait time after switching windows
global TOOLTIP_OFFSET_X    := 20       ; Tooltip offset from Roblox window's top-left corner
global TOOLTIP_OFFSET_Y    := 20
global MONITOR_INTERVAL_MS := 200      ; How often we refresh the tooltip / re-check Roblox
global TARGET_PROCESSES    := ["ahk_exe RobloxPlayerBeta.exe", "ahk_exe ApplicationFrameHost.exe"]

; ====== STATE (do not edit) ======
global AutoJumpActive := false
global StatusText     := ""
global CachedRobloxHwnd := 0           ; Cached window handle, refreshed by MonitorTooltip

; ====== HOTKEY ======
F8:: ToggleAutoJump()

; ====== CORE CONTROL ======
ToggleAutoJump() {
    global AutoJumpActive
    AutoJumpActive := !AutoJumpActive
    AutoJumpActive ? StartAutoJump() : StopAutoJump()
}

StartAutoJump() {
    global StatusText, INTERVAL_MS, MONITOR_INTERVAL_MS
    StatusText := "Auto Jump Roblox: ON`nInterval: " . (INTERVAL_MS / 60000) . " min"

    SetTimer(QuickJump, INTERVAL_MS)
    SetTimer(MonitorTooltip, MONITOR_INTERVAL_MS)
    QuickJump()   ; Run once immediately
}

StopAutoJump() {
    SetTimer(QuickJump, 0)
    SetTimer(MonitorTooltip, 0)
    ToolTip()
}

; ====== TOOLTIP ======
MonitorTooltip() {
    global StatusText, CachedRobloxHwnd
    CachedRobloxHwnd := FindRobloxWindow()

    if (CachedRobloxHwnd && WinActive("ahk_id " . CachedRobloxHwnd)) {
        WinGetPos(&winX, &winY, , , "ahk_id " . CachedRobloxHwnd)
        ToolTip(StatusText, winX + TOOLTIP_OFFSET_X, winY + TOOLTIP_OFFSET_Y)
    } else {
        ToolTip()   ; Hide when Roblox isn't in front (or not running)
    }
}

; ====== JUMP ======
QuickJump() {
    global CachedRobloxHwnd
    ; Reuse cached hwnd if still valid; otherwise look it up fresh
    if (!CachedRobloxHwnd || !WinExist("ahk_id " . CachedRobloxHwnd))
        CachedRobloxHwnd := FindRobloxWindow()

    if (!CachedRobloxHwnd)
        return

    targetWin := "ahk_id " . CachedRobloxHwnd
    previousWin := WinExist("A")

    WinActivate(targetWin)
    Sleep(FOCUS_DELAY_MS)
    SendSpaceTap()
    Sleep(FOCUS_DELAY_MS)

    if (previousWin && previousWin != CachedRobloxHwnd)
        WinActivate("ahk_id " . previousWin)
}

SendSpaceTap() {
    global HOLD_SPACE_MS
    Send("{Space down}")
    Sleep(HOLD_SPACE_MS)
    Send("{Space up}")
}

; ====== WINDOW LOOKUP ======
; Returns hwnd (0 if none found). Stops at first match in TARGET_PROCESSES.
FindRobloxWindow() {
    for proc in TARGET_PROCESSES {
        hwnd := WinExist(proc)
        if hwnd
            return hwnd
    }
    return 0
}