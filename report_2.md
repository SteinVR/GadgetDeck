# Steamworks Analysis and Implementation Plan

## 1. Background
`GadgetDeck` relies on the Steamworks Input API through the bundled **SteamworksPy** library.  SteamworksPy loads the native `steam_api` library and expects a `steam_appid.txt` file in the working directory.  This file currently contains the ID **480**, which is the public test game *Spacewar*.

When the program is launched, Steam detects App ID 480 and shows the account as "playing Spacewar".  Steam does not allow launching other games while a game ID is active, so running GadgetDeck blocks starting a real game on the same account.

The relevant code resides in `SteamworksPy/steamworks/__init__.py`:
```python
app_id_file = os.path.join(os.getcwd(), 'steam_appid.txt')
if not os.path.isfile(app_id_file):
    raise FileNotFoundError(f'steam_appid.txt missing from {os.getcwd()}')
with open(app_id_file, 'r') as f:
    self.app_id = int(f.read())
```
(around lines 91‑101)
This forces an App ID for every run.

`GadgetDeck/__main__.py` initializes Steamworks and calls the input API:
```python
self.steam = STEAMWORKS()
self.steam.initialize()
self.steam.Input.Init()
```
(lines 49‑51)
Without a valid App ID, `Steamworks.initialize()` fails, so the project currently ships with `steam_appid.txt`.

## 2. Can Steamworks be used without tying to "Spacewar"?
Steamworks requires a valid App ID for the Input API.  Using 480 works because everyone owns Spacewar, but Steam treats the process as that game.  A true solution would be running under a dedicated App ID that is marked as a **Tool** on Steam – tools can run while games are active.  Obtaining such an ID requires joining the Steamworks program and paying the publishing fee.

Removing `steam_appid.txt` or setting a fictitious ID prevents initialization.  The API itself cannot be used anonymously.  Because of this, the SteamworksPy code cannot be easily adjusted to avoid using an App ID; it would still need some ID that Steam recognizes.

## 3. Alternatives to Steamworks
Instead of using Steamworks, the Deck's own controller devices can be read directly from Linux input events.  Libraries such as `python-evdev` can access `/dev/input/event*` devices for buttons, sticks and trackpads.  By reading these events and forwarding them to the USB gadget code, GadgetDeck could function without Steam running and without any App ID.  This would also eliminate the Spacewar issue entirely.

## 4. Implementation Plan
1. **Investigate device nodes** – On the Steam Deck, list `/dev/input/` while pressing controls to confirm which event files correspond to each input.  Utilities like `evtest` can help map them.
2. **Prototype event reader** – Write a small Python module using the `evdev` library to read analog and digital events from those devices.  Verify axis ranges and button mappings.
3. **Integrate with GadgetDeck** – Replace the Steamworks initialization and polling thread in `GadgetDeck/__main__.py` with the new event reader.  The gadget update logic (joystick, mouse, keyboard) stays the same, only the source of input events changes.
4. **Remove Steamworks dependencies** – Delete the `SteamworksPy` directory and `steam_appid.txt`.  Update `requirements.txt`, the Makefile, and packaging scripts accordingly.
5. **Test without Steam** – Ensure the program still launches from the Steam library as a normal non‑Steam game and that the controls work when connected to a PC.  Because Steamworks is no longer used, it will not appear as Spacewar and will not block other games.
6. **Optional: Tool App ID** – If Steamworks features are still desired (e.g., for gyro or advanced configs), consider applying for a Steamworks Tool App ID and restoring the library with that ID.  This would require Valve approval and is outside the scope of open‑source distribution.

