{ pkgs ? import ./nixpkgs.nix }:

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  app.overrideAttrs (oldAttrs: {
    src = null; 

    # FIXME for laravel we must copy vendor dir and run composer dump-autoload
    shellHook = 
      ''
        [ ! -e vendor ] && mkdir vendor && cp -R ${app.deps}/* vendor
        chmod -R u+w vendor
        composer dump-autoload
        trap "rm -rf vendor" EXIT
      '';
  })

