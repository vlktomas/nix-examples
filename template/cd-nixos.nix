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

    network.description = "Network deployed to NixOS";

    server = {

      imports = [ deploymentNodes.server ];

      # get some secret from environment variable and store it under /run/ on a temporary filesystem
      deployment.keys.some-secret.text = "SOME_SECRET=${builtins.getEnv "SOME_SECRET"}";

      # ensure that key service is loaded before service which needs it
      systemd.services.example = {
        after = [ "some-secret-key.service" ];
        wants = [ "some-secret-key.service" ];
      };

      deployment.targetHost = "1.2.3.4";
    };

  }
