{ pkgs ? import ./nixpkgs.nix, localFiles ? true }:

with pkgs; callPackage ./app.nix { inherit localFiles; }

