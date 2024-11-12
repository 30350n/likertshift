#!/usr/bin/env bash

if [[ $# -ne 1 || -z "$1" ]]; then
    echo "usage: $(basename -- $0) <serial_device>"
    exit
fi

SCRIPT_DIR=$(dirname $(readlink -f "$0"))
DFU_FILE="$SCRIPT_DIR/s140_nrf52_7.3.0_softdevice.zip"

adafruit-nrfutil dfu genpkg \
    --dev-type 82 \
    --dev-revision 52840 \
    --softdevice "$SCRIPT_DIR/s140_nrf52_7.3.0_softdevice.hex" \
    "$DFU_FILE"    
adafruit-nrfutil dfu serial \
    --port "$1" \
    --baudrate 115200 \
    --touch 1200 \
    --package "$DFU_FILE"
rm $DFU_FILE
