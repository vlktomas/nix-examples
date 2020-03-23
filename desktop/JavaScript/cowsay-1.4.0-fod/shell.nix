{ pkgs ? import ./nixpkgs.nix }:

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  app.overrideAttrs (oldAttrs: {
    src = null; 

    # FIXME we must copy node_modules dir
    shellHook = 
      ''
        [ ! -e node_modules ] && mkdir node_modules && cp -R ${app.deps}/* node_modules
        chmod -R u+w node_modules
        trap "rm -rf node_modules" EXIT
      '';
  })

