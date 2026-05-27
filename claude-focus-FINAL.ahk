#Requires AutoHotkey v2.0
#SingleInstance Force
#include <UIA>

; ── Claude / Cowork — auto-launch + focus text box on Right Ctrl ─────────────
;
; On startup: launches Claude automatically with the accessibility flag.
; Right Ctrl: brings Claude to front from any window, desktop, or virtual
;             desktop, and focuses the text box ready to type.
; ────────────────────────────────────────────────────────────────────────────

; Request admin elevation if not already running as admin
if !A_IsAdmin {
    Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    ExitApp()
}

WIN_TITLE := "Claude"

; Use PowerShell to find Claude's install path — survives version updates
tempOut    := A_Temp "\claude_path.txt"
tempScript := A_Temp "\find_claude.ps1"
try FileDelete(tempScript)
FileAppend("(Get-AppxPackage *Claude*).InstallLocation | Out-File -FilePath '" . tempOut . "' -Encoding UTF8", tempScript)
RunWait("powershell -ExecutionPolicy Bypass -File " . tempScript,, "Hide")
CLAUDE_EXE := Trim(FileRead(tempOut), " `n`r") "\app\Claude.exe"
try FileDelete(tempScript)
try FileDelete(tempOut)

; Keep DetectHiddenWindows on so we can find Claude across virtual desktops
DetectHiddenWindows(true)

; Always relaunch Claude with the accessibility flag
if !FileExist(CLAUDE_EXE) {
    MsgBox("Claude.exe not found.`n`nPath tried:`n" CLAUDE_EXE, "claude-focus setup")
} else {
    TrayTip("Step 1: exe found at " CLAUDE_EXE, "claude-focus", 1)
    Sleep(2000)
    if WinExist(WIN_TITLE) {
        TrayTip("Step 2: closing Claude...", "claude-focus", 1)
        Sleep(2000)
        WinClose(WIN_TITLE)
        WinWaitClose(WIN_TITLE, , 5)
    } else {
        TrayTip("Step 2: Claude not running, skipping close", "claude-focus", 1)
        Sleep(2000)
    }
    TrayTip("Step 3: launching Claude...", "claude-focus", 1)
    Sleep(2000)
    Run('"' . CLAUDE_EXE . '" --force-renderer-accessibility')
    TrayTip("Step 4: waiting for window...", "claude-focus", 1)
    WinWait(WIN_TITLE, , 15)
    TrayTip("Step 5: waiting for accessibility tree...", "claude-focus", 1)
    Sleep(5000)
    TrayTip("Ready! Press Right Ctrl to focus Claude.", "claude-focus", 1)
}

RCtrl:: {
    hwnd := WinExist(WIN_TITLE)

    if !hwnd {
        MsgBox("Claude window not found.", "claude-focus")
        return
    }

    ; If Claude is on a different virtual desktop, pull it to this one first
    MoveToCurrentDesktop(hwnd)
    Sleep(300)

    ; Bring window to front
    DllCall("AllowSetForegroundWindow", "UInt", 0xFFFFFFFF)
    WinActivate("ahk_id " hwnd)
    WinWaitActive("ahk_id " hwnd, , 2)
    Sleep(400)

    root := UIA.ElementFromHandle(hwnd)

    try {
        textBox := root.FindElement({Name: "Write your prompt to Claude"})
    } catch as e {
        MsgBox("Could not find text box: " e.Message, "claude-focus")
        return
    }

    ; Approach 1: LegacyIAccessible Select (no mouse movement)
    try {
        legacyPattern := textBox.GetCurrentPattern(UIA.Pattern.LegacyIAccessible)
        legacyPattern.Select(1)   ; SELFLAG_TAKEFOCUS
        return
    }

    ; Approach 2: Invisible click at element's exact position
    rect := textBox.BoundingRectangle
    clickX := rect.l + (rect.r - rect.l) // 2
    clickY := rect.t + (rect.b - rect.t) // 2
    BlockInput("MouseMove")
    Click(clickX, clickY)
    BlockInput("MouseMoveOff")
}

; Uses IVirtualDesktopManager COM to move a window to the current desktop.
MoveToCurrentDesktop(hwnd) {
    static CLSID := "{AA509086-5CA9-4C25-8F95-589D3C07B48A}"
    static IID   := "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}"
    try {
        vdm := ComObject(CLSID, IID)
        isOnCurrent := 0
        ComCall(3, vdm, "Ptr", hwnd, "Int*", &isOnCurrent)
        if isOnCurrent
            return
        currentDesktopGuid := Buffer(16, 0)
        ComCall(4, vdm, "Ptr", A_ScriptHwnd, "Ptr", currentDesktopGuid)
        ComCall(5, vdm, "Ptr", hwnd, "Ptr", currentDesktopGuid)
    }
}
