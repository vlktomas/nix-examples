{ pkgs ? import ./nixpkgs.nix }:

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  app.overrideAttrs (oldAttrs: {
    src = null; 

    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ app.nodeShell ];

    # FIXME for laravel we must copy vendor dir and run composer dump-autoload
    shellHook = 
      ''
        [ ! -e vendor ] && mkdir vendor && cp -R ${app.phpDeps}/* vendor
        chmod -R u+w vendor
        composer dump-autoload
        ln -s ${app.nodePackage}/lib/node_modules/laravel-node-dependencies/node_modules node_modules
        alias cross-env='true &&'
        trap "rm -rf vendor node_modules" EXIT
      '';
  })

