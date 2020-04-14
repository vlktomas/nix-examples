{
  server = {

    nixpkgs.pkgs = (import ./nixpkgs.nix).pkgs;

    imports = [
      ./module.nix
    ];

    # get some secret from environment variable and store it under /run/ on a temporary filesystem
    deployment.keys.some-secret.text = builtins.getEnv "SOME_SECRET";

    # ensure that key service is loaded before service which needs it
    systemd.services.example = {
      after = [ "some-secret-key.service" ];
      wants = [ "some-secret-key.service" ];
    };

  };
}
