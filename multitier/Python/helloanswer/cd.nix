{
  nixpkgsSource ? null,
  localFiles ? true,
  clientLocally ? true
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
in
  {

    server = {

      nixpkgs.pkgs = pkgs;

      imports = [
        ./server/module.nix
      ] ++ lib.optional clientLocally ./client/module.nix;

      services.server.enable = true;
      services.server.port = 18812;

    } // lib.optionalAttrs (clientLocally) {

      client.serverUrl = "localhost";
      client.serverPort = 18812;
    };

  } // lib.optionalAttrs (!clientLocally) {

    client = {

      nixpkgs.pkgs = pkgs;

      imports = [
        ./client/module.nix
      ];

      client.serverUrl = "server";
      client.serverPort = 18812;
    };

  }
