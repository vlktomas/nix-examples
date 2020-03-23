{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.example;
  pkg = import ./default.nix { inherit pkgs };

in

  {

    # interface

    options.services.example = with types; {

      enable = mkEnableOption "Example";

    };

    # implementation

    config = mkIf cfg.enable {

      systemd.services.example = {
        description = "Run example program";
        wantedBy = [ "multi-user.target" ];
        path = [ pkg ];
        script = ''
          set -e
          example
        '';
      };

    };
  }

