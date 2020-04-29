{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.client;
  pkg = pkgs.client;
  pkgWrapped = pkgs.runCommand "client-wrapped"
    { buildInputs = [ pkg pkgs.makeWrapper ]; }
    ''
    mkdir -p $out/bin
    makeWrapper ${pkg}/bin/${pkg.executable} $out/bin/${pkg.executable}-wrapped --add-flags "${cfg.serverUrl} ${toString cfg.serverPort}"
    '';
in
  {

    # interface

    options.client = with types; {

      serverUrl = mkOption {
        type = str;
        default = "localhost";
        description = "Server URL.";
      };

      serverPort = mkOption {
        type = port;
        default = 18812;
        description = "Server RPC port.";
      };
    };

    # implementation

    config = {

      environment.systemPackages = [ pkgWrapped ];
    };

  }
