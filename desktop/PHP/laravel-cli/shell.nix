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
    shellHook = ''
      if [ ! -e vendor ] ; then
        mkdir -p vendor/composer
        cp ${appPackage.deps}/composer/* vendor/composer/
        shopt -s extglob
        ln -s ${appPackage.deps}/!(composer) vendor/
        composer dump-autoload
        DEPENDENCIES_LINKED=true
      fi

      exitHandler () {
          [ ! -z $DEPENDENCIES_LINKED ] && rm -rf vendor
      }

      trap exitHandler EXIT
    '';
  }
