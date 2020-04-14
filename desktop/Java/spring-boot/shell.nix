{ pkgs ? (import ./nixpkgs.nix).pkgs }:

let
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  app.overrideAttrs (oldAttrs: {
    src = null; 

    shellHook = 
      ''
        alias mvn='mvn -Dmaven.repo.local="${app.deps}"'
      '';
  })

