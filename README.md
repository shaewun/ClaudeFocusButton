# Claude Focus Hotkey — Setup Guide

Press **Right Ctrl** from anywhere — any window, the desktop, or a different virtual desktop — and Claude instantly comes to front with the text box focused and ready to type.

> **Virtual desktop behavior:** the hotkey switches you to whichever desktop Claude is currently on, rather than moving Claude to your current desktop. This is intentional — Claude stays put and you jump to it.

---

## What you need

- **Windows 10 or 11**
- **Claude desktop app** (Cowork) installed
- **AutoHotkey v2** with UI Access — download from [autohotkey.com](https://www.autohotkey.com/)
  - During install, make sure to select **v2**
  - Use the **`AutoHotkey_UIA.exe`** variant — this is required for the accessibility features to work
- **UIA-v2 library** by Descolada — [github.com/Descolada/UIA-v2](https://github.com/Descolada/UIA-v2)

---

## Step 1 — Install AutoHotkey v2

Download and run the installer from [autohotkey.com](https://www.autohotkey.com/). Select **v2** during install. After installing, you'll have both `AutoHotkey.exe` (standard) and `AutoHotkey_UIA.exe` (UI Access) available — the script requires the UIA variant.

---

## Step 2 — Install the UIA-v2 library

1. Go to [github.com/Descolada/UIA-v2](https://github.com/Descolada/UIA-v2)
2. Click the green **Code** button → **Download ZIP**
3. Extract the ZIP
4. Inside the extracted folder, find the **`Lib`** folder
5. Copy that `Lib` folder to:
   ```
   C:\Users\[YourUsername]\Documents\AutoHotkey\Lib\
   ```
   Create the `Lib` folder if it doesn't exist.

---

## Step 3 — Set AutoHotkey_UIA.exe as the default handler

The script must be launched with `AutoHotkey_UIA.exe`, not the standard `AutoHotkey.exe`. To configure this:

1. Right-click `claude-focus-FINAL.ahk` → **Open with** → **Choose another app**
2. Browse to your AutoHotkey install folder (usually `C:\Program Files\AutoHotkey\v2\`)
3. Select **`AutoHotkey_UIA.exe`**
4. Check **Always use this app** and confirm

---

## Step 4 — Add the script to startup

1. Press `Win+R`, type `shell:startup`, hit Enter
2. Copy `claude-focus-FINAL.ahk` into that folder

The script will now run automatically every time you log in.

---

## How it works

**On startup**, the script:

1. Requests admin elevation (UAC prompt) if not already running as admin
2. Uses PowerShell to find Claude's install path automatically — no hardcoded path, survives app updates
3. Closes Claude if it's already running
4. Relaunches Claude with the `--force-renderer-accessibility` flag, which exposes Claude's UI elements to the accessibility system
5. Waits for Claude to fully load, then shows a series of tray tip notifications in the bottom-right corner confirming progress, ending with **"Ready! Press Right Ctrl to focus Claude."**

These startup notifications are normal and only appear once at login.

**When you press Right Ctrl**, the script:

1. Locates the Claude window (including across virtual desktops)
2. Switches you to whichever desktop Claude is on
3. Brings the Claude window to front
4. Focuses the text input box via the accessibility tree — no mouse cursor movement

---

## Troubleshooting

**"Claude.exe not found" on startup**
The PowerShell lookup for the Claude AppX package returned nothing. Make sure the Claude desktop app is installed. If it's installed but the error persists, open the script in a text editor, find the `CLAUDE_EXE` line, and replace it with the full hardcoded path to `Claude.exe` (find it via Task Manager → right-click the Claude process → Open file location).

**Text box doesn't get focused**
The script must be the one that launches Claude so it can apply `--force-renderer-accessibility`. If you opened Claude manually before the script ran, close it and let the script relaunch it on next login.

**Nothing happens when pressing Right Ctrl**
Confirm the script is running — look for an AHK icon in your system tray. Also make sure it's being run with `AutoHotkey_UIA.exe` and not the standard `AutoHotkey.exe`.

**Right Ctrl gives "Claude window not found" right after startup**
Wait for the "Ready!" tray tip before using the hotkey — Claude's accessibility tree needs a few seconds to fully initialize after launch.
