{ nixpkgsSource ? null }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage;
in
  appPackage.overrideAttrs (oldAttrs: {
    src = null;

    shellHook =
      ''
        [ ! -e vendor ] && ln -s ${appPackage.deps} vendor
        trap "rm vendor" EXIT
      '';
  })

