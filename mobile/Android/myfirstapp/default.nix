{ pkgs ? import ./nixpkgs.nix, localFiles ? true, release ? false }:

with pkgs; callPackage ./app.nix { inherit localFiles release; }

