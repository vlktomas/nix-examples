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
      export PATH="$PWD/node_modules/.bin/:$PATH"

      if [ ! -e node_modules ] ; then
        mkdir node_modules
        cp -R ${appPackage.deps}/* node_modules
        chmod -R u+w node_modules
        DEPENDENCIES_LINKED=true
      fi

      exitHandler () {
          [ ! -z $DEPENDENCIES_LINKED ] && rm -rf node_modules
      }

      trap exitHandler EXIT
    '';
  }
