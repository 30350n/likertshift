SCRIPT_DIR=$(dirname $(readlink -f "$0"))
probe-rs erase --chip nrf52840_xxAA
probe-rs download --verify --format hex --chip nrf52840_xxAA \
    "$SCRIPT_DIR/s140_nrf52_7.3.0_softdevice.hex"
