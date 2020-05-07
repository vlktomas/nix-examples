{
  nixpkgsSource ? null,
  localFiles ? true,
  workersCount ? 1
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  deploymentNodes = import ./cd.nix {
    inherit nixpkgsSource localFiles workersCount;
  };
in
  {

    network.description = "Spark Pi deployed to VirtualBox";

    master = { config, ... }: {

      imports = [ deploymentNodes.master ];

      services.pi.masterIp = config.networking.privateIPv4;
      services.pi.submitArgs = "--executor-memory 512M --driver-memory 512M";

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1536;
      deployment.virtualbox.vcpu = 2;
    };

  } // lib.listToAttrs (map (n: lib.nameValuePair "worker${lib.fixedWidthNumber 2 n}" ({ config, ... }: {

    imports = [ deploymentNodes."worker${lib.fixedWidthNumber 2 n}" ];

    services.pi.workerArgs = "--memory 768M";
    services.pi.workerIp = config.networking.privateIPv4;

    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.memorySize = 1536;
    deployment.virtualbox.vcpu = 2;

  })) (lib.range 1 workersCount))

