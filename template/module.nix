{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.example;
  pkg = pkgs.example;
in
  {

    # interface

    options.services.example = with types; {

      enable = mkEnableOption "Example";

      someSecretFile = mkOption {
        type = nullOr path;
        default = null;
        example = "/run/keys/some-secret";
        description = "A file containing some secret.";
      };
    };

    # implementation

    config = mkIf cfg.enable {

      systemd.services.example = {
        description = "Example service";
        wantedBy = [ "multi-user.target" ];
        path = [ pkg ];
        script = ''
          set -e
          example
        '';
        serviceConfig = {
          EnvironmentFile = cfg.someSecretFile;
          PassEnvironment = "SOME_SECRET";
        };
      };

    };

  }
