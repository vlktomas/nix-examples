# this file should be independent of NixOps
{
  nixpkgsSource ? null,
  localFiles ? true,
  someSecretFile ? builtins.toFile "some-secret" "SOME_SECRET=secret"
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
in
  {

    server = {

      nixpkgs.pkgs = pkgs;

      imports = [
        ./module.nix
      ];
    };

  }
