# inspired by /nixos/modules/services/mail/sympa.nix and /nixos/modules/services/web-apps/mediawiki.nix

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.fastapi;
  user = "fastapi";
  group = config.services.httpd.group;
  pkg = pkgs.fastapi;
in
  {

    # interface

    options.services.fastapi = with types; {

      enable = mkEnableOption "FastAPI example";

      hostName = mkOption {
        type = str;
        default = "localhost";
        description = "Web hostname.";
      };

      virtualHost = mkOption {
        type = nullOr (submodule (import <nixpkgs/nixos/modules/services/web-servers/nginx/vhost-options.nix>));
        example = literalExample ''
          {
            forceSSL = true;
            enableACME = true;
            locations."/" = {
              proxyPass = "http://localhost:3000";
            };
          }
        '';
        default = null;
        description = ''
          Further nginx configuration can be done by adapting
          <option>services.nginx.virtualHosts.&lt;hostName&gt;</option>.
        '';
      };
    };

    # implementation

    config = mkIf cfg.enable {

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      security.acme.acceptTerms = true;
      security.acme.email = "admin@${cfg.hostName}";

      services.nginx = {
        enable = true;
        virtualHosts =
          let
            defaultVirtualHost = rec {
              forceSSL = true;
              enableACME = true;
              locations."/" = {
                proxyPass = "http://localhost:8000";
              };
            };
          in
            {
              "${cfg.hostName}" = if (cfg.virtualHost != null) then
                (mkMerge [
                  cfg.virtualHost defaultVirtualHost
                ])
              else
                defaultVirtualHost;
            };
      };

      systemd.services.reporters = {
        description = "Uvicorn service";
        wantedBy = [ "multi-user.target" ];
        path = [ pkg ];
        script = ''
          ${pkg}/bin/.dev-wrapped
        '';
      };
    };
  }
