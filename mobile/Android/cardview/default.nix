{ pkgs ? (import ./nixpkgs.nix).pkgs, localFiles ? true, release ? false }:

with pkgs; callPackage ./app.nix { inherit localFiles release; }

