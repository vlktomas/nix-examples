{ nixpkgsSource ? null }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage;
in
  pkgs.mkShell {
    inputsFrom = [ appPackage ];
    src = null;

    # FIXME for laravel we must copy vendor dir and run composer dump-autoload
    shellHook = ''
      [ ! -e vendor ] && mkdir vendor && cp -R ${appPackage.deps}/* vendor
      chmod -R u+w vendor
      composer dump-autoload
      trap "rm -rf vendor" EXIT
    '';
  }
