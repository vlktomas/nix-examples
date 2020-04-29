{ nixpkgsSource ? null }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage;

  # Extra sources to include in the gopath
  extraSrcs = [ ];

  # Extra gopaths containing src subfolder
  # with sources to include in the gopath
  extraSrcPaths = [ ];

  goPath = extraSrcs;
in
  pkgs.mkShell {
    inputsFrom = [ appPackage ];
    src = null;

    # restore shellHook from older version of buildGoModule
    shellHook = ''
      d=$(mktemp -d "--suffix=-$name")
    '' + toString (map (dep: ''
      mkdir -p "$d/src/$(dirname "${dep.goPackagePath}")"
      ln -s "${dep.src}" "$d/src/${dep.goPackagePath}"
    ''
    ) goPath) + ''
      export GOPATH=${lib.concatStringsSep ":" ( ["$d"] ++ ["$GOPATH"] ++ ["$PWD"] ++ extraSrcPaths)}
    '';
  }
