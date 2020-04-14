{ pkgs ? (import ./nixpkgs.nix).pkgs }:

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; release = false; };
in
  pkgs.mkShell {
    inputsFrom = [ app ];
    src = null;
  }

