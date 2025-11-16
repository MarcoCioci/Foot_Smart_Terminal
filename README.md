
# Smart Foot Terminal (Foot + tmux, single clean window)

> A small utility that opens a new **Foot** window attached to an existing **tmux** session while **preserving one pane's state** (history, scrollback), and **closes other Foot windows** to avoid clutter.
>
> * Default tmux session: `main` (override via `SESSION_NAME=...`)
> * Default Foot app-id: `foot-terminal` (override via `APP_ID=...`)
> * TERM inside Foot: `foot-direct` (override via `TERM_FOR_FOOT=...`)

## Requirements

> * Linux on Wayland recommended
> * `foot`, `tmux`, `pgrep`, `ps`, `awk` available in `PATH`

## Install

> ```bash
> git clone https://github.com/<your-username>/focus-foot.git
> cd focus-foot
> chmod +x install.sh
> ./install.sh
> ```
>
> This installs:
>
> * Script → `~/.local/bin/focus_or_spawn_terminal.sh`
> * Desktop entry → `~/.local/share/applications/foot-smart.desktop`
>
> You should now see **Smart Foot Terminal** in your app launcher.

## Usage

> * Click **Smart Foot Terminal** from the launcher
> * Or run:
>
> ```bash
> ~/.local/bin/focus_or_spawn_terminal.sh
> ```

 ## Recommended tmux settings

> * Click **Smart Foot Terminal** from the launcher
> Add the following to your ```~/. tmux.conf``` to make scrolling smooth with Foot + tmux:
> Enable mouse so the wheel works in copy-mode
> ```bash
> set -g mouse on
> ```
> * A modern terminfo entry inside tmux (pairs well with Foot)
> ```bash
> set -g default-terminal "tmux-256color"
> ```
> * Reload without restarting:
> ```bash
> tmux source-file ~/.tmux.conf
> ```
## Optional: Keyboard Shortcut (GNOME)

> **GUI method**
>
> 1. Settings → Keyboard → Keyboard Shortcuts → **Custom Shortcuts** → “+”
> 2. **Name:** Smart Foot Terminal
>    **Command:** `sh -lc "$HOME/.local/bin/focus_or_spawn_terminal.sh"`
> 3. Set your preferred keybinding (e.g., `Super+Return`).
>
> **CLI method (example binding to Super+Return)**
>
> ```bash
> # Create a new custom keybinding slot
> path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/smart-foot/"
> gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
> gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path name "Smart Foot Terminal"
> gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path command "sh -lc \"$HOME/.local/bin/focus_or_spawn_terminal.sh\""
> gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path binding "<Super>Return"
> ```

## Uninstall

> ```bash
> rm -f ~/.local/bin/focus_or_spawn_terminal.sh
> rm -f ~/.local/share/applications/foot-smart.desktop
> update-desktop-database ~/.local/share/applications || true
> ```

## Why this design?

> * We **snapshot Foot PIDs before** launching the new window → we never kill the one we just opened.
> * We attach the new Foot to a **specific tmux pane** (keeps history).
> * We prune other Foot windows by checking which Foot process is the **parent** of the preserved pane’s shell PID.

## Configuration knobs

> Environment variables (override at runtime):
>
> ```bash
> SESSION_NAME=main APP_ID=foot-terminal TERM_FOR_FOOT=foot-direct ~/.local/bin/focus_or_spawn_terminal.sh
> ```

##  Warning / Caveats
- This script **closes other Foot windows**.  
  - If those windows were **attached to tmux**, the jobs **keep running** in the tmux session (tmux is a server); you can reattach later and nothing is lost.  
  - If a Foot window was **not using tmux** (plain shell/program), closing it will **terminate** whatever was running there.
- Practical rule of thumb:
  - **Safe:** all your work lives inside the same tmux session (default: `main`).  
  - **Risky:** you have Foot windows running commands **outside** tmux.
- Alternate screen apps (e.g., `less`, `vim`, `htop`) manage scrolling independently; history lives in the underlying shell pane.


### 2025-11 Update: Selection Fix
Touchpad selection disappearing was caused by `set -g mouse on` in tmux.
Disable it to allow Wayland/foot to manage selection correctly.
