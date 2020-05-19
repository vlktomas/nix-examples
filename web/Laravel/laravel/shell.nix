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
    shellHook = ''
      export PATH="$PWD/vendor/bin/:$PATH"

      if [ ! -e vendor ] ; then
        mkdir -p vendor/composer
        cp ${appPackage.phpDeps}/composer/* vendor/composer/
        shopt -s extglob
        ln -s ${appPackage.phpDeps}/!(composer) vendor/
        composer dump-autoload
        PHP_DEPENDENCIES_LINKED=true
      fi

      export PATH="$PWD/node_modules/.bin/:$PATH"

      if [ ! -e node_modules ] ; then
        ln -s ${appPackage.nodePackage}/lib/node_modules/laravel-node-dependencies/node_modules node_modules
        NODE_DEPENDENCIES_LINKED=true
      fi

      exitHandler () {
          [ ! -z $PHP_DEPENDENCIES_LINKED ] && rm -rf vendor
          [ ! -z $NODE_DEPENDENCIES_LINKED ] && rm node_modules
      }

      trap exitHandler EXIT
    '';
  }
