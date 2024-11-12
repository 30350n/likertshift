{
    rust_overlay ? (import (
        builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"
    )),
    pkgs ? import <nixpkgs> {overlays = [rust_overlay];},
}:
pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [
        (rust-bin.nightly.latest.default.override {
            targets = ["thumbv7em-none-eabihf"];
            extensions = [
                "rust-src"
                "rust-analyzer"
            ];
        })
        adafruit-nrfutil
        cargo
        cargo-udeps
        probe-rs
        rustfmt
        scrcpy
    ];
}
