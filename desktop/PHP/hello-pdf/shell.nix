{ pkgs ? import ./nixpkgs.nix }:

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  app.overrideAttrs (oldAttrs: {
    src = null; 

    shellHook = 
      ''
        [ ! -e vendor ] && ln -s ${app.deps} vendor
        trap "rm vendor" EXIT
      '';
  })

