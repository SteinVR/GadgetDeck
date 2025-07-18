# GadgetDeck Analysis (AICODE)

This repository provides scripts and packages for a tool that allows the Steam Deck to emulate a USB controller when plugged into another PC. Below are plans addressing the issues in the prompt.

## Implementation Plan: Identify GadgetDeck correctly in Steam
1. **Root Cause**: `steam_appid.txt` sets the app ID to `480`, which is the game *Spacewar*. When launched through Steam, the Deck is seen as playing this game.
2. **Goal**: Launch GadgetDeck without showing the user as playing a game, while retaining Steam Input features.
3. **Steps**
   - Investigate if Steam Input can work with app id `0` or a tool-type ID. Test by editing `steam_appid.txt` and confirming that `STEAMWORKS()` still initializes.
   - If Steam requires a valid ID, register a free Steamworks tool ID or request Valve for one. Replace `steam_appid.txt` with that ID and update packaging scripts.
   - Adjust `setup` script and `Makefile` so the proper `steam_appid.txt` is copied into the installed directory.
   - Document the chosen ID and update instructions in `README.md`.
4. **Testing**: After changes, install GadgetDeck and confirm Steam no longer reports playing *Spacewar* and controller mappings still load.

## Implementation Plan: Investigate & fix crashes
1. **Observation**: After a crash GadgetDeck may fail to start until reinstalled. Likely the USB gadget services are left in a bad state or files become missing.
2. **Steps**
   - Add logging to `gadget-deck-manager.py` and `__main__.py` to capture failures when activating services or initializing Steamworks.
   - Provide a recovery script (e.g., `gadget-deck-reset`) that stops and disables gadget services and removes any stale USB gadget nodes.
   - Modify the application start-up code to attempt cleanup before launching services (`systemctl restart gadget-deck@{joystick,mouse,keyboard}`).
   - Ensure `steam_appid.txt` and other resources are present; if missing, recreate them from `/usr/share/gadget-deck` during start-up.
   - Document troubleshooting steps in the README.
3. **Testing**: Simulate crashes by force-quitting the process and verify that running the reset script allows the application to start again without reinstalling.
