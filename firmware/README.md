### Building

```console
$ cargo build --release
```

### Flashing

```console
$ bash .vscode/upload_firmware_dfu.sh target/thumbv7em-none-eabihf/release/likertshift-firmware /dev/<serialPort>
```
