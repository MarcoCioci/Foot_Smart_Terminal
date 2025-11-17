# **Foot Smart Terminal (Wayland Foot + tmux Single-Window Preserver)**

A small utility that opens a new **Foot** window attached to an existing **tmux** session while **preserving one pane’s state** (history, scrollback, running jobs), and **closing all other Foot windows** to avoid clutter.

This provides a consistent, clean terminal workflow on **Wayland**, where focusing/raising existing windows is not possible.

Default behavior:

* tmux session: `main` (override with `SESSION_NAME=...`)
* Foot app-id: `foot-terminal`
* Terminal value inside Foot: `foot-direct`
* Fully compatible with **GNOME Wayland**, **Sway**, **Hyprland**, **KDE Plasma Wayland**

---

## **Requirements**

* A Linux system running Wayland (GNOME, KDE, Sway, Hyprland, etc.)
* `foot`
* `tmux`
* Common UNIX tools: `pgrep`, `ps`, `awk`

Install dependencies on Ubuntu:

```bash
sudo apt install foot tmux
```

---

## **Install**

```bash
git clone https://github.com/<your-username>/Foot_Smart_Terminal.git
cd Foot_Smart_Terminal
chmod +x install.sh
./install.sh
```

This installs:

* `foot_smart_terminal` → `~/.local/bin`
* `foot-smart-terminal.desktop` → `~/.local/share/applications`

You can now search **Smart Foot Terminal** from your application launcher.

---

## **Usage**

### **From the launcher**

Start **Smart Foot Terminal** like any regular application.

### **From the terminal**

```bash
foot_smart_terminal
```

What happens internally:

1. Your tmux session (`main`) is inspected.
2. The **first pane** is treated as the “preserved” pane.
3. A new Foot window attaches to that tmux pane.
4. All *other* Foot windows are closed.
5. The preserved pane keeps **scrollback**, **history**, and any running processes.

---

## **Why this matters on Wayland**

* Foot provides its own native text selection.
* tmux mouse mode interferes with that (especially on Wayland).
* The configuration used here ensures:

  * **native Foot selection works normally**
  * **scrollback is always available via Ctrl+Space**
  * **tmux does not steal Wayland’s selection events**

This results in a hybrid workflow with both tmux scrollback and Foot-native selection working together.

---

## **Optional: GNOME Keyboard Shortcut**

### GUI Method

1. Settings → Keyboard → Keyboard Shortcuts
2. Add Custom Shortcut

   * **Name:** Smart Foot Terminal
   * **Command:**

     ```bash
     sh -lc "$HOME/.local/bin/foot_smart_terminal"
     ```
3. Assign your preferred shortcut (e.g., **Super+Return**, **Ctrl+Alt+T**).

### CLI Method

```bash
path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/smart-foot/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path name "Smart Foot Terminal"
gsettings set org.gnome/settings-daemon/plugins/media-keys/custom-keybinding:$path command "sh -lc \"$HOME/.local/bin/foot_smart_terminal\""
gsettings set org.gnome/settings-daemon/plugins/media-keys/custom-keybinding:$path binding "<Super>Return"
```

---

## **Uninstall**

```bash
rm -f ~/.local/bin/foot_smart_terminal
rm -f ~/.local/share/applications/foot-smart-terminal.desktop
update-desktop-database ~/.local/share/applications || true
```

---

## **How it works**

### **Preserving a single pane**

Wayland does not allow scripts to raise or focus an existing terminal window.
Instead:

* the script always opens a new Foot window,
* determines which window corresponds to the preserved tmux pane,
* and closes all other Foot windows.

Result:

* the new window becomes the only one
* the preserved tmux pane keeps its history and job state
* the workflow stays clean and predictable

### **Why Foot PIDs are captured before launching**

This prevents accidentally killing the brand-new Foot window that the script itself launches.

### **How the preserved window is identified**

We use process hierarchy:

```
tmux pane PID → its parent Foot window PID
```

Any Foot process not matching that relationship is removed.

---

## **Configuration**

Environment variables allow customization:

```bash
SESSION_NAME=dev \
APP_ID=foot-terminal \
TERM_FOR_FOOT=foot-direct \
foot_smart_terminal
```

---

## **Caveats / Warnings**

* This script **will close all Foot windows not tied to the preserved tmux pane**.
* If those windows were running shells *outside tmux*, those shells terminate.
* If they were running tmux panes, **jobs survive** (because tmux is a server).

**Rule of thumb:**
Always do your work inside tmux. Everything survives window cleanup.

Applications using alternate screen (vim, htop, less, etc.) manage scroll independently.

---

## **2025-11 Update: Selection Fix (Wayland)**

If text selection disappears as soon as you attempt to scroll, it usually happens because:

* `set -g mouse on` in tmux breaks Wayland selection
* Wayland terminals rely on native selection mechanics

**Solution:**

* Keep tmux mouse mode **off**
* Use native Foot selection normally
* Use **Ctrl+Space** to toggle tmux scrollback mode when needed

This configuration is stable across all major Wayland compositors.

---