{
  nixpkgsSource ? null,
  localFiles ? true
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
in
  {

    webserver = {

      nixpkgs.pkgs = pkgs;

      imports = [
        ./module.nix
      ];

      services.fastapi.enable = true;

    };

  }
