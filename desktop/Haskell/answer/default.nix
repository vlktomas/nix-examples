{ pkgs ? import ./nixpkgs.nix, localFiles ? true }:

with pkgs; haskellPackages.callPackage ./app.nix { inherit localFiles; }

