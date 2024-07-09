{
    rust_overlay ? (import (
        builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"
    )),
    pkgs ? import <nixpkgs> {overlays = [rust_overlay];},
}:
pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [
        (rust-bin.stable.latest.default.override {
            targets = ["thumbv7em-none-eabihf"];
            extensions = [
                "rust-src"
                "rust-analyzer"
            ];
        })
        cargo
        probe-rs
        rustfmt
        scrcpy
    ];
}
