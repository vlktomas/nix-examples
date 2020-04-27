{ nixpkgsSource ? null }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage;
in
  # The function overrideCabal lets you alter the arguments to the mkDerivation function.
  # Override app with overrideAttrs is not sufficient.
  (pkgs.haskell.lib.overrideCabal appPackage (old: {
    src = null;
  })).env.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with pkgs.haskellPackages; [ cabal-install ]);
  })

