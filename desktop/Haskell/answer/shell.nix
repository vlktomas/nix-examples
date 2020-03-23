{ pkgs ? import ./nixpkgs.nix }:

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  # The function overrideCabal lets you alter the arguments to the mkDerivation function.
  # Override app with overrideAttrs is not sufficient.
  (pkgs.haskell.lib.overrideCabal app (old: {
    src = null;
  })).env.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with pkgs.haskellPackages; [ cabal-install ]);
  })

