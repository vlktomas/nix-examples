{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.server;
  pkg = pkgs.server;
in
  {

    # interface

    options.services.server = with types; {

      enable = mkEnableOption "Server";

      port = mkOption {
        type = port;
        default = 18812;
        description = "RPC port.";
      };
    };

    # implementation

    config = mkIf cfg.enable {

      systemd.services.server = {
        description = "Server service";
        wantedBy = [ "multi-user.target" ];
        path = [ pkg ];
        script = ''
          ${pkg}/bin/${pkg.executable} ${toString cfg.port}
        '';
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];
    };

  }
