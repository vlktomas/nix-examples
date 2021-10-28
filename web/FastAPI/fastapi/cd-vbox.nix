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

    network.description = "FastAPI deployed to VirtualBox";

    webserver = {

      imports = [ deploymentNodes.webserver ];

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024;
      deployment.virtualbox.vcpu = 2;
    };

  }

