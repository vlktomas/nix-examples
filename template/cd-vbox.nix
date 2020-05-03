{
  nixpkgsSource ? null,
  localFiles ? true
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  deploymentNodes = import ./cd.nix {
    inherit nixpkgsSource localFiles;
    someSecretFile = "/run/keys/some-secret";
  };
in
  {

    network.description = "Network deployed to VirtualBox";

    server = {

      imports = [ deploymentNodes.server ];

      # store secret under /run/ on a temporary filesystem
      deployment.keys.some-secret.text = "SOME_SECRET=secret";

      # ensure that key service is loaded before service which needs it
      systemd.services.example = {
        after = [ "some-secret-key.service" ];
        wants = [ "some-secret-key.service" ];
      };

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024; # megabytes
      deployment.virtualbox.vcpu = 2; # number of cpus
    };

  }
