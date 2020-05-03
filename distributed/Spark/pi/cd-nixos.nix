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

    network.description = "Spark Pi deployed to NixOS";

    master = {

      imports = [ deploymentNodes.master ];

      services.pi.masterIp = "1.2.3.4";

      deployment.targetHost = "1.2.3.4";
    };

  } // lib.listToAttrs (map (n: lib.nameValuePair "worker${lib.fixedWidthNumber 2 n}" {

    imports = [ deploymentNodes."worker${lib.fixedWidthNumber 2 n}" ];

    services.pi.workerIp = "1.2.3.${toString (10 +n)}";

    deployment.targetHost = "1.2.3.${toString (10 + n)}";

  }) (lib.range 1 workersCount))
