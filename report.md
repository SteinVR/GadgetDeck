# AICODE-GadgetDeck Report

## Analysis of Installation and Structure

GadgetDeck emulates a game controller on the Steam Deck. The README explains its purpose:

```
# GadgetDeck
This is a program to emulate a game controller on the Steam Deck when connected over USB to another computer.
```
(from README.md lines 1-3)

Installation involves running the setup script as root:
```
curl -s https://raw.githubusercontent.com/Frederic98/GadgetDeck/main/setup | sudo bash
```
(from README.md lines 20-23)

The installer downloads a release zip and copies files into `/usr/share/gadget-deck`:
```
wget -P GadgetDeck https://github.com/Frederic98/GadgetDeck/releases/download/V0.1/GadgetDeck.zip
cd GadgetDeck
unzip GadgetDeck.zip
su $SUDO_USER -c make
make install
cp -r GadgetDeck /usr/share/gadget-deck/
chmod +x /usr/share/gadget-deck/GadgetDeck/GadgetDeck
sudo -u $SUDO_USER bash -c "steamos-add-to-steam /usr/share/gadget-deck/GadgetDeck/GadgetDeck"
```
(from setup lines 8-17)

`make install` places utilities and service units in the system:
```
INSTALL_DIR = /usr/share/gadget-deck
install:
        mkdir -p $(INSTALL_DIR)
        cp gadget-deck-manager.py $(INSTALL_DIR)/
        chmod +x $(INSTALL_DIR)/gadget-deck-manager.py
        cp -r "HID Descriptors" $(INSTALL_DIR)
        pip install -r requirements.txt
        cp util/gadget-deck*.service /etc/systemd/system/
        cp util/99-gadget-deck.rules /etc/polkit-1/rules.d/
```
(from Makefile lines 24-33)

On launch, the application ensures gadget services are running:
```
for gadget in ('joystick', 'mouse', 'keyboard'):
    if subprocess.call(['systemctl', 'is-active', '--quiet', f'gadget-deck@{gadget}.service']) != 0:
        print(f'Gadget {gadget} not active, starting...')
        subprocess.call(['systemctl', 'start', f'gadget-deck@{gadget}.service'])
```
(from GadgetDeck/__main__.py lines 116-120)

Steamworks is initialized to get controller input:
```
self.steam = STEAMWORKS()
self.steam.initialize()
self.steam.Input.Init()
```
(from GadgetDeck/__main__.py lines 49-51)

The file `steam_appid.txt` sets the Steam App ID to 480:
```
480
```
(steam_appid.txt line 1)

## Implementation Plan: run GadgetDeck without appearing as Spacewar
1. Remove `steam_appid.txt` from the repository and release package to prevent Steam from always forcing AppID 480.
2. Modify `GadgetDeck/__main__.py` to set `SteamAppId` only when not already defined. Example:
   ```python
   import os
   if not os.getenv("SteamAppId"):
       os.environ["SteamAppId"] = "480"
       os.environ["SteamGameId"] = "480"
   ```
   This lets Steam provide its own ID when launched from the Steam library, so the program appears as a non‑Steam application instead of “Spacewar.”
3. Update `Makefile` and packaging scripts to exclude `steam_appid.txt` and deploy the changed Python file.
4. Rebuild the release zip and adjust the setup script so the install step copies the new files.
5. Inform users they may still see “Spacewar” if run outside of Steam; launching via the Steam library will use a custom name.

## Implementation Plan: investigate and mitigate crash issues
1. Add logging around startup and Steamworks initialization in `__main__.py` to capture exceptions and service startup failures into `/var/log/gadget-deck.log`.
2. Ensure systemd units restart on failure by adding `Restart=on-failure` to `gadget-deck@.service` and related services.
3. Create a wrapper script (or modify the launcher) that verifies `gadget-deck-base.service` is active and relaunches it if necessary before starting the UI.
4. Package required Python dependencies inside the release (virtual environment) so library updates on the system don’t break the binary.
5. Provide a troubleshooting script that resets the install directory and reinstalls the service files without needing a full reinstall.
