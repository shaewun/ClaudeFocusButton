#Requires AutoHotkey v2.0
#SingleInstance Force
#include <UIA>

; ── Claude / Cowork — overlay hotkeys ────────────────────────────────────────
;
; On startup: closes and relaunches Claude with --force-renderer-accessibility.
;
; Right Ctrl              : open Claude fullscreen (or close it)
; Right Shift + Right Ctrl: open Claude split-right, current app split-left (or close)
;
; On open  — Claude launches fresh on the current desktop, sized and focused.
; On close — Claude is closed, previous window restored to its original size/position.
; ─────────────────────────────────────────────────────────────────────────────

if !A_IsAdmin {
    Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    ExitApp()
}

WIN_TITLE := "Claude"
WIN_EXE   := "Claude.exe"
WIN_CLASS := "Chrome_WidgetWin_1"
WIN_QUERY := WIN_TITLE " ahk_class " WIN_CLASS " ahk_exe " WIN_EXE

; Find Claude's install path via PowerShell — survives version updates
tempOut    := A_Temp "\claude_path.txt"
tempScript := A_Temp "\find_claude.ps1"
try FileDelete(tempScript)
FileAppend("(Get-AppxPackage *Claude*).InstallLocation | Out-File -FilePath '" . tempOut . "' -Encoding UTF8", tempScript)
RunWait("powershell -ExecutionPolicy Bypass -File " . tempScript,, "Hide")
CLAUDE_EXE := Trim(FileRead(tempOut), " `n`r") "\app\Claude.exe"
try FileDelete(tempScript)
try FileDelete(tempOut)

DetectHiddenWindows(true)

; Startup: close any running instance and relaunch with accessibility flag
if !FileExist(CLAUDE_EXE) {
    MsgBox("Claude.exe not found.`n`nPath tried:`n" CLAUDE_EXE, "claude-focus setup")
} else {
    TrayTip("Step 1: exe found at " CLAUDE_EXE, "claude-focus", 1)
    Sleep(2000)
    if WinExist(WIN_QUERY) {
        TrayTip("Step 2: closing Claude...", "claude-focus", 1)
        Sleep(2000)
        WinClose(WIN_QUERY)
        WinWaitClose(WIN_QUERY, , 5)
    } else {
        TrayTip("Step 2: Claude not running, skipping close", "claude-focus", 1)
        Sleep(2000)
    }
    TrayTip("Step 3: launching Claude...", "claude-focus", 1)
    Sleep(2000)
    Run('"' . CLAUDE_EXE . '" --force-renderer-accessibility')
    TrayTip("Step 4: waiting for window...", "claude-focus", 1)
    WinWait(WIN_QUERY, , 15)
    TrayTip("Step 5: waiting for accessibility tree...", "claude-focus", 1)
    Sleep(5000)
    TrayTip("Ready! Right Ctrl = fullscreen  |  RShift+RCtrl = split", "claude-focus", 1)
}

; ── State ─────────────────────────────────────────────────────────────────────
global overlayMode    := ""
global prevHwnd       := 0
global prevX          := 0, prevY := 0, prevW := 0, prevH := 0
global prevMaximized  := false
global prevFullscreen := false   ; true when previous window was a fullscreen exclusive app

; ── Hotkeys ───────────────────────────────────────────────────────────────────

RCtrl:: {
    if (overlayMode != "")
        DismissOverlay()
    else
        ActivateOverlay("full")
}

RShift & RCtrl:: {
    if (overlayMode != "")
        DismissOverlay()
    else
        ActivateOverlay("split")
}

; ── Core functions ────────────────────────────────────────────────────────────

ActivateOverlay(mode) {
    global overlayMode, prevHwnd, prevX, prevY, prevW, prevH, prevMaximized, prevFullscreen, CLAUDE_EXE, WIN_QUERY

    ; Save the currently active window before we do anything
    prevHwnd       := WinExist("A")
    prevFullscreen := false

    ; Release Chrome's accessibility hold if switching from Chrome
    if (WinGetClass("A") = "Chrome_WidgetWin_1") {
        PostMessage(0x0086, 0, 0, , "A")
        Sleep(150)
    }

    ; Shell windows (desktop, taskbar): no real previous window — open Claude fullscreen
    if !prevHwnd || IsShellWindow(prevHwnd) {
        prevHwnd := 0
        GetMonitorWorkArea(0, &mLeft, &mTop, &mRight, &mBottom)
        LaunchAndFocus("full", mLeft, mTop, mRight - mLeft, mBottom - mTop)
        overlayMode := "full"
        return
    }

    ; Fullscreen exclusive app: save hwnd so we can re-activate it on dismiss,
    ; but always open Claude fullscreen (splitting over a fullscreen app is unreliable)
    if IsFullscreenExclusive(prevHwnd) {
        prevFullscreen := true
        GetMonitorWorkArea(0, &mLeft, &mTop, &mRight, &mBottom)
        LaunchAndFocus("full", mLeft, mTop, mRight - mLeft, mBottom - mTop)
        overlayMode := "full"
        return
    }

    ; Save previous window's size and state so we can restore it on close
    WinGetPos(&prevX, &prevY, &prevW, &prevH, "ahk_id " prevHwnd)
    prevMaximized := (WinGetMinMax("ahk_id " prevHwnd) = 1)

    ; Get the work area of the monitor the previous window is on
    GetMonitorWorkArea(prevHwnd, &mLeft, &mTop, &mRight, &mBottom)
    mW := mRight - mLeft
    mH := mBottom - mTop

    if (mode = "full") {
        LaunchAndFocus(mode, mLeft, mTop, mW, mH)
    } else {
        ; Snap previous app to left half before launching Claude on the right
        halfW := mW // 2
        WinRestore("ahk_id " prevHwnd)
        WinMove(mLeft, mTop, halfW, mH, "ahk_id " prevHwnd)
        LaunchAndFocus(mode, mLeft + halfW, mTop, halfW, mH)
    }

    overlayMode := mode
}

; Launch Claude (always fresh — opens on current desktop), move to position, focus text box
LaunchAndFocus(mode, x, y, w, h) {
    global CLAUDE_EXE, WIN_QUERY

    Run('"' . CLAUDE_EXE . '" --force-renderer-accessibility')
    if !WinWait(WIN_QUERY, , 15) {
        MsgBox("Claude didn't open in time.", "claude-focus")
        return
    }

    claudeHwnd := WinExist(WIN_QUERY)

    ; Give Electron a moment to render before we try to move or interact with it
    Sleep(2000)

    ; Maximize first so Electron reflows at full size, then snap to target.
    ; Skipping this causes the UI to get stuck in a narrow layout on split mode.
    WinMaximize("ahk_id " claudeHwnd)
    Sleep(600)
    WinRestore("ahk_id " claudeHwnd)
    Sleep(200)
    WinMove(x, y, w, h, "ahk_id " claudeHwnd)
    Sleep(500)

    DllCall("AllowSetForegroundWindow", "UInt", 0xFFFFFFFF)
    WinActivate("ahk_id " claudeHwnd)
    WinWaitActive("ahk_id " claudeHwnd, , 2)
    Sleep(300)
    FocusTextBox(claudeHwnd)
}

DismissOverlay() {
    global overlayMode, prevHwnd, prevX, prevY, prevW, prevH, prevMaximized, prevFullscreen, WIN_QUERY

    ; Close Claude
    if WinExist(WIN_QUERY)
        WinClose(WIN_QUERY)

    ; Restore the previous window to exactly how it was
    if prevHwnd && WinExist("ahk_id " prevHwnd) {
        if prevFullscreen {
            ; Fullscreen app manages its own layout — just bring it back to front
            WinActivate("ahk_id " prevHwnd)
        } else if prevMaximized {
            WinMaximize("ahk_id " prevHwnd)
            WinActivate("ahk_id " prevHwnd)
        } else {
            WinRestore("ahk_id " prevHwnd)
            WinMove(prevX, prevY, prevW, prevH, "ahk_id " prevHwnd)
            WinActivate("ahk_id " prevHwnd)
        }
    }

    overlayMode    := ""
    prevHwnd       := 0
    prevFullscreen := false
}

; Retries up to 10 times — Electron needs a moment after launch/resize
FocusTextBox(hwnd) {
    textBox := ""
    loop 10 {
        root := UIA.ElementFromHandle(hwnd)
        try {
            textBox := root.FindElement({Name: "Write your prompt to Claude"})
            break
        }
        Sleep(500)
    }
    if !textBox {
        MsgBox("Could not find text box after retries.", "claude-focus")
        return
    }
    ; Primary: focus via accessibility pattern — no mouse movement
    try {
        legacyPattern := textBox.GetCurrentPattern(UIA.Pattern.LegacyIAccessible)
        legacyPattern.Select(1)
        return
    }
    ; Fallback: click the center of the element's bounding rectangle
    rect := textBox.BoundingRectangle
    clickX := rect.l + (rect.r - rect.l) // 2
    clickY := rect.t + (rect.b - rect.t) // 2
    BlockInput("MouseMove")
    Click(clickX, clickY)
    BlockInput("MouseMoveOff")
}

; ── Helpers ───────────────────────────────────────────────────────────────────

GetWindowMonitor(hwnd) {
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    cx := wx + ww // 2
    cy := wy + wh // 2
    loop MonitorGetCount() {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (cx >= mL && cx < mR && cy >= mT && cy < mB)
            return A_Index
    }
    return MonitorGetPrimary()
}

GetMonitorWorkArea(hwnd, &left, &top, &right, &bottom) {
    mon := hwnd ? GetWindowMonitor(hwnd) : MonitorGetPrimary()
    MonitorGetWorkArea(mon, &left, &top, &right, &bottom)
}

IsFullscreenExclusive(hwnd) {
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    mon := GetWindowMonitor(hwnd)
    MonitorGet(mon, &mLeft, &mTop, &mRight, &mBottom)
    style := WinGetStyle("ahk_id " hwnd)
    ; Coverage check (<=/>= ) instead of exact equality so DPI-scaled apps and
    ; borderless-fullscreen windows that land a pixel or two off still match
    coversScreen := (wx <= mLeft && wy <= mTop
                     && wx + ww >= mRight && wy + wh >= mBottom)
    noCaption := !(style & 0xC00000)
    return coversScreen && noCaption
}

; Returns true if hwnd is a Windows shell window (desktop, taskbar) —
; these should be treated the same as "no real previous window"
IsShellWindow(hwnd) {
    class := WinGetClass("ahk_id " hwnd)
    return (class = "Progman" || class = "WorkerW" || class = "Shell_TrayWnd")
}
