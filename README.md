# **Smart Foot Terminal (Wayland Foot + tmux Single-Window Preserver)**

A small utility that opens a new **Foot** window attached to an existing **tmux** session while **preserving one pane’s state** (history, scrollback), and **closing all other Foot windows** to avoid clutter.

This gives you a consistent, always-clean terminal workflow on **Wayland**, where normal focusing/raising of windows is NOT possible.

* Default tmux session: `main` (override with `SESSION_NAME=...`)
* Default Foot app-id: `foot-terminal`
* Default terminal setting inside Foot: `foot-direct`
* Works fully under **GNOME Wayland**, **Sway**, **Hyprland**, **KDE Plasma Wayland**

---

## **Requirements**

* Linux on **Wayland** (GNOME, KDE, Sway, Hyprland…)
* `foot`
* `tmux`
* Common UNIX tools: `pgrep`, `ps`, `awk`

Everything is already installed on Ubuntu, except foot:

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

* `focus_or_spawn_terminal.sh` → `~/.local/bin`
* `foot-smart.desktop` → `~/.local/share/applications`

Now search **Smart Foot Terminal** in your GNOME launcher.

---

## **Usage**

### From launcher

Open **Smart Foot Terminal** like any application.

### From CLI

```bash
~/.local/bin/focus_or_spawn_terminal.sh
```

What happens:

1. Your tmux session (`main`) is inspected.
2. The **first pane** is marked as "preserved".
3. A new Foot window attaches to that pane.
4. All other Foot windows are closed.
5. The preserved pane keeps **scrollback**, **history**, and **running jobs**.


### Why this matters on Wayland

* Wayland/Foot performs text selection natively.
* tmux "mouse mode" breaks selection, making it yellow and temporary.
* With this config:

  * **Natural Foot text selection works**
  * **Scrollback is one keypress away (Ctrl+Space)**

Perfect hybrid mode.

---

## **Optional: GNOME Keyboard Shortcut**

### GUI method

1. Settings → Keyboard → Keyboard Shortcuts
2. Add Custom Shortcut

   * **Name:** Smart Foot Terminal
   * **Command:**

     ```bash
     sh -lc "$HOME/.local/bin/focus_or_spawn_terminal.sh"
     ```
3. Assign shortcut (e.g. **Super+Return** or **Ctrl+Alt+T**).

### CLI method

```bash
path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/smart-foot/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path name "Smart Foot Terminal"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path command "sh -lc \"$HOME/.local/bin/focus_or_spawn_terminal.sh\""
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path binding "<Super>Return"
```

---

## **Uninstall**

```bash
rm -f ~/.local/bin/focus_or_spawn_terminal.sh
rm -f ~/.local/share/applications/foot-smart.desktop
update-desktop-database ~/.local/share/applications || true
```

---

## **How it works (the design)**

### **Why preserving a single pane?**

Because Wayland *does not allow* scripts to focus or raise an existing terminal window.
So instead:

* We always create a **new** Foot window
* Then instantly kill all Foot windows **except** the one tied to the preserved tmux pane
* Result:

  * The new window becomes **the only active one**
  * The preserved pane keeps its entire history and ongoing jobs
  * The workflow always stays clean

### **Why snapshot Foot PIDs before launching?**

To avoid killing the Foot window we just opened.

### **How do we detect the preserved window?**

We map:

```
tmux pane PID  →  its parent Foot window PID
```

Any Foot window not parenting the preserved pane is removed.

---

## **Configuration knobs**

All configurable via environment variables:

```bash
SESSION_NAME=dev \
APP_ID=foot-terminal \
TERM_FOR_FOOT=foot-direct \
~/.local/bin/focus_or_spawn_terminal.sh
```

---

## **Caveats / Warnings**

* This script **kills all Foot windows not tied to the preserved pane**.
* If those windows run **bare shells or commands outside tmux**, they will end.
* But if those windows run **tmux panes**, the jobs survive — tmux is a server.

**Rule of thumb:**
Always work inside tmux. Everything survives window cleanup.

**Note:**
Applications using alternate screen (vim, htop, less) handle scroll independently.

---

## **2025–11 Update: Selection Fix (Wayland)**

If selection disappears as soon as you lift your fingers:

✔ It was caused by `set -g mouse on` inside tmux.
✘ tmux mouse mode steals pointer events on Wayland.

**Solution:**
Leave tmux mouse **off**, and use:

* **native Foot selection**
* **Ctrl+Space** to enter tmux scroll mode

This gives stable behavior on all Wayland compositors.

---