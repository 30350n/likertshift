#!/usr/bin/env bash

if [[ $# -ne 0 ]]; then
    echo "usage: $(basename -- $0)"
    exit
fi

SCRIPT_DIR=$(dirname $(readlink -f "$0"))

probe-rs erase \
    --chip nrf52840_xxAA
probe-rs download \
    --chip nrf52840_xxAA \
    --verify \
    --format hex \
    "$SCRIPT_DIR/s140_nrf52_7.3.0_softdevice.hex"
