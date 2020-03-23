{ pkgs ? import ./nixpkgs.nix }:

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; release = false; };
in
  app.overrideAttrs (oldAttrs: {
    src = null; 
  })

