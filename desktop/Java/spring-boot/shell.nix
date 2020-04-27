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
        alias mvn='mvn -Dmaven.repo.local="${appPackage.deps}"'
      '';
  })

