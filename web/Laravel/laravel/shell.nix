{ nixpkgsSource ? null }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage;
in
  pkgs.mkShell {
    nativeBuildInputs = [ appPackage.nodeShell ];
    inputsFrom = [ appPackage ];
    src = null;

    # FIXME for laravel we must copy vendor dir and run composer dump-autoload
    shellHook = ''
      [ ! -e vendor ] && mkdir vendor && cp -R ${appPackage.phpDeps}/* vendor
      chmod -R u+w vendor
      composer dump-autoload
      ln -s ${appPackage.nodePackage}/lib/node_modules/laravel-node-dependencies/node_modules node_modules
      alias cross-env='true &&'
      trap "rm -rf vendor node_modules" EXIT
    '';
  }