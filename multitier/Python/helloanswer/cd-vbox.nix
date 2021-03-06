{
  nixpkgsSource ? null,
  localFiles ? true,
  clientLocally ? true
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  deploymentNodes = import ./cd.nix {
    inherit nixpkgsSource localFiles clientLocally;
  };
in
  {

    network.description = "Helloanswer deployed to VirtualBox";

    server = {

      imports = [ deploymentNodes.server ];

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024;
      deployment.virtualbox.vcpu = 2;
    };

    client = {

      imports = [ deploymentNodes.client ];

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024;
      deployment.virtualbox.vcpu = 2;
    };

  }
