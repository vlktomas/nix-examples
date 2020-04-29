{ nixpkgsSource ? null }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage;
  pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [ numpy ]);
in
  pkgs.mkShell {
    buildInputs = [ pythonWithPackages ];
    src = null;
  }

  # or
  #pythonWithPackages.env

  # setuptools development mode
  /*
  pkgs.mkShell {
    inputsFrom = [ appPackage ];
    src = null;
  }
  */

  # use python -m module
