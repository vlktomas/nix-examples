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

    network.description = "Network deployed to VirtualBox";

    server = {

      imports = [ deploymentNodes.server ];

      server = {
        deployment.targetEnv = "virtualbox";
        deployment.virtualbox.memorySize = 1024; # megabytes
        deployment.virtualbox.vcpu = 2; # number of cpus
      };
    };

    client = {

      imports = [ deploymentNodes.client ];

      server = {
        deployment.targetEnv = "virtualbox";
        deployment.virtualbox.memorySize = 1024; # megabytes
        deployment.virtualbox.vcpu = 2; # number of cpus
      };
    };

  }
