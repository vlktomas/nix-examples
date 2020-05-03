{
  nixpkgsSource ? null,
  localFiles ? true,
  workersCount ? 1
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;

  makeWorker = config: n: lib.nameValuePair "worker${lib.fixedWidthNumber 2 n}" config;
in
  {

    master = {

      nixpkgs.pkgs = pkgs;

      imports = [
        ./module.nix
      ];

      services.pi = {
        enable = true;
        master = true;
        workersCount = workersCount;
      };

    };

  } // lib.listToAttrs (map (makeWorker {

    nixpkgs.pkgs = pkgs;

    imports = [
      ./module.nix
    ];

    services.pi = {
      enable = true;
      worker = true;
      masterHost = "master";
    };

  }) (lib.range 1 workersCount))

