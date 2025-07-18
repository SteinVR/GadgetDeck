#!/usr/bin/env bash
# Reset GadgetDeck install and reinstall service files
set -e
INSTALL_DIR=/usr/share/gadget-deck

echo "Stopping GadgetDeck services..."
systemctl stop gadget-deck@joystick.service gadget-deck@mouse.service gadget-deck@keyboard.service gadget-deck@mtp.service gadget-deck@shell.service gadget-deck-base.service 2>/dev/null || true

echo "Removing install directory: $INSTALL_DIR"
rm -rf "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
cp -r GadgetDeck_installed/GadgetDeck "$INSTALL_DIR/" || true
cp gadget-deck-manager.py "$INSTALL_DIR/"
cp -r "HID Descriptors" "$INSTALL_DIR/"

echo "Reinstalling service files..."
cp util/gadget-deck*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable gadget-deck-base.service

echo "Reset complete. Start GadgetDeck from Steam or with 'systemctl start gadget-deck-base.service'."
