{ nixpkgsSource ? null, localFiles ? true, release ? false }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage.override { inherit release; };
in

  builtins.trace "Nixpkgs version: ${lib.version}"
  builtins.trace "Use local files: ${lib.boolToString localFiles}"
  builtins.trace "Release: ${lib.boolToString release}"

  appPackage
