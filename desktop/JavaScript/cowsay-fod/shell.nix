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

    # FIXME we must copy node_modules dir
    shellHook = ''
      [ ! -e node_modules ] && mkdir node_modules && cp -R ${appPackage.deps}/* node_modules
      chmod -R u+w node_modules
      trap "rm -rf node_modules" EXIT
    '';
  }
