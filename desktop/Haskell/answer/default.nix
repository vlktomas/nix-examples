{ pkgs ? (import ./nixpkgs.nix).pkgs, localFiles ? true }:

with pkgs; haskellPackages.callPackage ./app.nix { inherit localFiles; }

