{ nixpkgsSource ? null, release ? false }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage.override { inherit release; };
in
  pkgs.mkShell {
    inputsFrom = [ appPackage ];
    src = null;
    shellHook = ''
      export GRADLE_USER_HOME=$(mktemp -d)
      export ANDROID_SDK_ROOT=${pkgs.androidsdk_9_0}/libexec/android-sdk
      export ANDROID_HOME=${pkgs.androidsdk_9_0}/libexec
      export ANDROID_SDK_HOME=$(mktemp -d)
      export PATH="$ANDROID_SDK_ROOT/bin:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/28.0.3:$PATH"
      export GRADLE_INIT=${appPackage.gradleInit}
    '';
  }
