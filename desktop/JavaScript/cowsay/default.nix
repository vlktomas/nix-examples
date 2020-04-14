{ pkgs ? (import ./nixpkgs.nix).pkgs, localFiles ? true }:

with pkgs; callPackage ./app.nix { inherit localFiles; }

