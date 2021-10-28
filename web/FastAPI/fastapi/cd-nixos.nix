{
  nixpkgsSource ? null,
  localFiles ? true
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  deploymentNodes = import ./cd.nix { inherit nixpkgsSource localFiles; };
in
  {

    network.description = "FastAPI deployed to NixOS";

    webserver = {

      imports = [ deploymentNodes.webserver ];

      deployment.targetHost = "1.2.3.4";
    };

  }

