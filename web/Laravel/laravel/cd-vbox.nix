{
  nixpkgsSource ? null,
  localFiles ? true,
  storageLocally ? true,
  databaseLocally ? true
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  deploymentNodes = import ./cd.nix {
    inherit nixpkgsSource localFiles storageLocally databaseLocally;
    appKeyFile = "/run/keys/app-key";
    databasePasswordFile = "/run/keys/db-password";
  };
in
  {

    network.description = "Laravel deployed to VirtualBox";

    webserver = {

      imports = [ deploymentNodes.webserver ];

      # generated as 'base64:' . base64_encode(random_bytes(32))
      deployment.keys.app-key.text = "APP_KEY=base64:eFMkq9zwjK42i7qXiN04rTKKWhD5FexWO9zetWawTXg=";
      deployment.keys.db-password.text = "DB_PASSWORD=password";

      systemd.services.httpd = {
        after = [ "app-key-key.service" ] ++ lib.optional (!databaseLocally) "db-password-key.service";
        wants = [ "app-key-key.service" ] ++ lib.optional (!databaseLocally) "db-password-key.service";
      };

      systemd.services.laravel-cron = {
        after = [ "app-key-key.service" ] ++ lib.optional (!databaseLocally) "db-password-key.service";
        wants = [ "app-key-key.service" ] ++ lib.optional (!databaseLocally) "db-password-key.service";
      };

      systemd.services.laravel-database-migration = {
        after = [ "app-key-key.service" ] ++ lib.optional (!databaseLocally) "db-password-key.service";
        wants = [ "app-key-key.service" ] ++ lib.optional (!databaseLocally) "db-password-key.service";
      };

      systemd.services.laravel-database-seed = {
        after = [ "app-key-key.service" ] ++ lib.optional (!databaseLocally) "db-password-key.service";
        wants = [ "app-key-key.service" ] ++ lib.optional (!databaseLocally) "db-password-key.service";
      };

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 1024;
      deployment.virtualbox.vcpu = 2;
    };

  } // lib.optionalAttrs (!storageLocally) {

    fileserver = {

      imports = [ deploymentNodes.fileserver ];

      deployment.targetEnv = "virtualbox";
    };

  } // lib.optionalAttrs (!databaseLocally) {

    databaseserver = { config, ... }: {

      imports = [ deploymentNodes.databaseserver ];

      deployment.keys.initial-script.text =
        ''
          CREATE DATABASE IF NOT EXISTS `example`;
          CREATE USER IF NOT EXISTS 'laravel'@'webserver' IDENTIFIED WITH mysql_native_password;
          ALTER USER 'laravel'@'webserver' IDENTIFIED BY 'password';
          GRANT ALL PRIVILEGES ON example.* TO 'laravel'@'webserver';
        '';

      services.mysql.initialScript = "/run/keys/initial-script";

      systemd.services.mysql = {
        after = [ "initial-script-key.service" ];
        wants = [ "initial-script-key.service" ];
      };

      deployment.targetEnv = "virtualbox";
    };

  }
