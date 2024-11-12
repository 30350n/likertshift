#!/usr/bin/env bash

if [[ $# -ne 2 || -z "$1" || -z "$2" ]]; then
    echo "usage: $(basename -- $0) <firmware_elf> <serial_device>"
    exit
fi

FIRMWARE_ELF="$1"
HEX_FILE="${FIRMWARE_ELF%.*}.hex"
DFU_FILE="${FIRMWARE_ELF%.*}.zip"

objcopy $FIRMWARE_ELF -O ihex $HEX_FILE
adafruit-nrfutil dfu genpkg \
    --dev-type 82 \
    --dev-revision 52840 \
    --application "$HEX_FILE" \
    "$DFU_FILE"
adafruit-nrfutil dfu serial \
    --port "$2" \
    --baudrate 115200 \
    --touch 1200 \
    --package "$DFU_FILE"
