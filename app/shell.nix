{
    pkgs ?
        import <nixpkgs> {
            config = {
                android_sdk.accept_license = true;
                allowUnfree = true;
            };
        },
    androidPkgs ? (
        pkgs.androidenv.composeAndroidPackages
        {
            buildToolsVersions = ["34.0.0" "33.0.1"];
            platformVersions = ["34" "33"];
            abiVersions = ["armeabi-v7a" "arm64-v8a" "x86_64"];
            includeSystemImages = true;
            systemImageTypes = ["google_apis"];
        }
    ),
}:
pkgs.mkShell {
    ANDROID_SDK_ROOT = "${androidPkgs.androidsdk}/libexec/android-sdk";
    nativeBuildInputs = with pkgs.buildPackages; [
        androidPkgs.androidsdk
        flutter322
        jdk19
    ];
}
