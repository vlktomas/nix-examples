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

    master = {

      imports = [ deploymentNodes.master ];

      services.pi.masterIp = "192.168.56.101";
      services.pi.submitArgs = "--executor-memory 512M --driver-memory 512M";

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1536; # megabytes
      deployment.virtualbox.vcpu = 2; # number of cpus
    };

  } // lib.listToAttrs (map (n: lib.nameValuePair "worker${lib.fixedWidthNumber 2 n}" {

    imports = [ deploymentNodes."worker${lib.fixedWidthNumber 2 n}" ];

    services.pi.workerArgs = "--memory 768M";
    services.pi.workerIp = "192.168.56.1${lib.fixedWidthNumber 2 (n+1)}";

    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.memorySize = 1536; # megabytes
    deployment.virtualbox.vcpu = 2; # number of cpus

  }) (lib.range 1 workersCount))
