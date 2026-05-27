# Claude Focus — Setup Guide

Press **Right Ctrl** from anywhere to open Claude as a fullscreen overlay, or **Right Shift + Right Ctrl** to open it as a split-screen panel alongside your current app. Press either hotkey again to dismiss Claude and return to exactly where you were.

> **Virtual desktop behavior:** Claude always closes and relaunches on your current desktop — you never have to switch desktops to reach it.

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
3. Verifies Claude is installed and shows a **"Ready!"** tray notification in the bottom-right corner

**When you press a hotkey**, the script:

1. Saves the currently active window's size, position, and state
2. Closes and relaunches Claude so it opens on your current desktop
3. Positions Claude (fullscreen or right half) and focuses the text input box automatically

**When you press the hotkey again**, the script:

1. Closes Claude completely
2. Restores the previous window to its exact original size and position
3. Returns focus to that window

---

## Troubleshooting

**"Claude.exe not found" on startup**
The PowerShell lookup for the Claude AppX package returned nothing. Make sure the Claude desktop app is installed. If it's installed but the error persists, open the script in a text editor, find the `CLAUDE_EXE` line, and replace it with the full hardcoded path to `Claude.exe` (find it via Task Manager → right-click the Claude process → Open file location).

**Text box doesn't get focused**
The script launches Claude with `--force-renderer-accessibility` each time you press the hotkey. If Claude is already open from a manual launch (without that flag), close it first — the next hotkey press will relaunch it correctly.

**Nothing happens when pressing Right Ctrl**
Confirm the script is running — look for an AHK icon in your system tray. Also make sure it's being run with `AutoHotkey_UIA.exe` and not the standard `AutoHotkey.exe`.

**Hotkey unresponsive right after startup**
Wait for the "Ready!" tray notification before using the hotkey — Claude's accessibility tree needs a few seconds to fully initialize after first launch.

**Known edge case**: On certain Windows Explorer or GitHub repository pages, the UIA accessibility bridge can interfere with text box focus. The hotkey still opens Claude correctly; the text box may just need a manual click.
