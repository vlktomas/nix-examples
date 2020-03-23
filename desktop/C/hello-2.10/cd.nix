{
  webserver =
    { config, pkgs, ... }:
    {

      imports = [
        ./module.nix
      ];

      deployment.targetHost = "1.2.3.4";
    };
}
