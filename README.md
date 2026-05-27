# Claude Focus — Overlay Hotkeys for Windows

Summon Claude as a fullscreen overlay or a split-screen panel from anywhere on your desktop — then dismiss it and return to exactly where you were, with a single keypress.

| Hotkey | Action |
|---|---|
| **Right Ctrl** | Open Claude fullscreen — press again to close |
| **Right Shift + Right Ctrl** | Open Claude split-right, snap current app to left half — press either hotkey to close |

Claude closes completely on dismiss and reopens fresh on your current desktop every time. Because Claude persists its session state even when the window is closed, it picks up exactly where you left off — instantly, with no loading screen.

---

## What you need

- **Windows 10 or 11**
- **Claude desktop app** installed — [claude.ai/download](https://claude.ai/download)
- **AutoHotkey v2** — [autohotkey.com](https://www.autohotkey.com/)
  - Select **v2** during install
  - The script requires the **`AutoHotkey_UIA.exe`** variant (installed alongside the standard exe)
- **UIA-v2 library** by Descolada — [github.com/Descolada/UIA-v2](https://github.com/Descolada/UIA-v2)

---

## Setup

### Step 1 — Install AutoHotkey v2

Download and run the installer from [autohotkey.com](https://www.autohotkey.com/). Select **v2** during install. You'll end up with both `AutoHotkey.exe` (standard) and `AutoHotkey_UIA.exe` (UI Access) — the script requires the UIA variant.

### Step 2 — Install the UIA-v2 library

1. Go to [github.com/Descolada/UIA-v2](https://github.com/Descolada/UIA-v2)
2. Click **Code → Download ZIP** and extract it
3. Copy the **`Lib`** folder from inside the extracted archive to:
   ```
   C:\Users\[YourUsername]\Documents\AutoHotkey\Lib\
   ```
   Create the `Lib` folder if it doesn't exist.

### Step 3 — Set AutoHotkey_UIA.exe as the default handler

The script must run under `AutoHotkey_UIA.exe`, not the standard `AutoHotkey.exe`:

1. Right-click `claude-focus-FINAL.ahk` → **Open with → Choose another app**
2. Browse to your AutoHotkey install folder (usually `C:\Program Files\AutoHotkey\v2\`)
3. Select **`AutoHotkey_UIA.exe`**
4. Check **Always use this app** and confirm

### Step 4 — Add to startup

1. Press `Win+R`, type `shell:startup`, hit Enter
2. Copy `claude-focus-FINAL.ahk` into that folder

The script will now run automatically every time you log in.

---

## How it works

**On startup**, the script:

1. Requests admin elevation (UAC prompt) if not already running as admin
2. Uses PowerShell to locate Claude's install path automatically — no hardcoded paths, survives app updates
3. Verifies Claude is installed and shows a **"Ready!"** tray notification in the bottom-right corner

**When you press Right Ctrl or Right Shift + Right Ctrl**, the script:

1. Detects the currently active window and saves its size, position, and maximized state
2. Closes and relaunches Claude — this ensures it opens on your current desktop every time, with no virtual desktop switching
3. Moves Claude to the target position (fullscreen or right half), maximizing first so Electron reflows at full size before snapping to the final dimensions
4. Focuses the text input box via the Windows accessibility tree — no mouse movement required

**When you press the hotkey again**, the script:

1. Closes Claude completely
2. Restores the previous window to its exact original size and position
3. Returns focus to that window

**Special cases handled automatically:**

- **Empty desktop / taskbar**: Claude opens fullscreen with nothing to restore
- **Fullscreen exclusive apps** (games, video players): Claude opens fullscreen on top; dismissing re-activates the fullscreen app
- **Split mode from desktop or fullscreen app**: Falls back to fullscreen Claude automatically

---

## Troubleshooting

**"Claude.exe not found" on startup**
The PowerShell lookup for the Claude AppX package returned nothing. Make sure the Claude desktop app is installed. If it's installed but the error persists, open the script in a text editor, find the `CLAUDE_EXE` line, and replace the PowerShell block with the full hardcoded path to `Claude.exe` (find it via Task Manager → right-click Claude → Open file location).

**Text box doesn't get focused**
The script launches Claude with `--force-renderer-accessibility` each time you press the hotkey. If Claude is already open from a manual launch (without that flag), close it first — the next hotkey press will relaunch it correctly.

**Nothing happens when pressing Right Ctrl**
Confirm the script is running — look for an AHK icon in your system tray. Also make sure it's being run with `AutoHotkey_UIA.exe` and not the standard `AutoHotkey.exe`.

**Hotkey unresponsive right after startup**
Wait for the "Ready!" tray notification before using the hotkey — Claude's accessibility tree needs a few seconds to fully initialize after first launch.

**Known edge case**: On certain pages in Windows Explorer or specific GitHub repository pages, the UIA accessibility bridge can interfere with the text box focus step. The hotkey still opens Claude correctly; the text box may just need a manual click. This appears to be a quirk of how Windows handles UIA focus when those windows are in the foreground.
