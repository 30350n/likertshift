{
    pkgs ? import <nixpkgs> {},
    unstable ?
        import <unstable> {
            config = {
                android_sdk.accept_license = true;
                allowUnfree = true;
            };
        },
    androidPkgs ? (
        unstable.androidenv.composeAndroidPackages
        {
            buildToolsVersions = ["35.0.0" "33.0.1"];
            platformVersions = ["35" "34" "33"];
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
        unstable.flutter326
        jdk19
    ];
}
