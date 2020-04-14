{
  network.description = "Laravel";

  webserver = {nodes, ...}: {

    nixpkgs.pkgs = (import ./nixpkgs.nix).pkgs;

    imports = [
      ./module.nix
    ];

    # generated as 'base64:' . base64_encode(random_bytes(32))
    deployment.keys.app-key.text = "APP_KEY=base64:eFMkq9zwjK42i7qXiN04rTKKWhD5FexWO9zetWawTXg=";
    deployment.keys.db-password.text = "DB_PASSWORD=password";

    systemd.services.httpd = {
      after = [ "app-key-key.service" "db-password-key.service" ];
      wants = [ "app-key-key.service" "db-password-key.service" ];
    };

    systemd.services.laravel-cron = {
      after = [ "app-key-key.service" "db-password-key.service" ];
      wants = [ "app-key-key.service" "db-password-key.service" ];
    };

    systemd.services.laravel-database-migration = {
      after = [ "app-key-key.service" "db-password-key.service" ];
      wants = [ "app-key-key.service" "db-password-key.service" ];
    };

    systemd.services.laravel-database-seed = {
      after = [ "app-key-key.service" "db-password-key.service" ];
      wants = [ "app-key-key.service" "db-password-key.service" ];
    };

    # we can specify storage and database as local services or use another machines
    services.laravel = {
      enable = true;
      database.createLocally = true;
      #database.seed = true;
      #database.host = "databaseserver";
      #database.port = 3306;
      #database.port = nodes.databaseserver.config.services.mysql.port;
      #database.name = "example";
      #database.username = "laravel";
      #database.passwordFile = "/run/keys/db-password";
      app.keyFile = "/run/keys/app-key";
      app.storage.createLocally = true;
      #app.storage.path = "/mnt/data";
    };

    /*
    fileSystems."/mnt/data" = {
      fsType = "nfs4";
      device = "fileserver:/var/data";
    };
    */
  };

  /*
  databaseserver = {pkgs, ... }: {

    nixpkgs.pkgs = (import ./nixpkgs.nix).pkgs;

    deployment.keys.initial-script.text = ''
      CREATE DATABASE IF NOT EXISTS `example`;
      CREATE USER IF NOT EXISTS 'laravel'@'webserver' IDENTIFIED WITH mysql_native_password;
      ALTER USER 'laravel'@'webserver' IDENTIFIED BY 'password';
      GRANT ALL PRIVILEGES ON example.* TO 'laravel'@'webserver';
    '';

    networking.firewall.allowedTCPPorts = [ 3306 ];

    services.mysql = {
      enable = true;
      initialScript = "/run/keys/initial-script";
      package = pkgs.mariadb;
    };

    systemd.services.mysql = {
      after = [ "initial-script-key.service" ];
      wants = [ "initial-script-key.service" ];
    };
  };
  */

  /*
  fileserver = {

    nixpkgs.pkgs = (import ./nixpkgs.nix).pkgs;

    networking.firewall.allowedTCPPorts = [ 111 2049 ];
    networking.firewall.allowedUDPPorts = [ 111 2049 ];

    systemd.tmpfiles.rules = [
      "d  /var/data                       0775 root root - -"
      "d  /var/data/app                   0775 root root - -"
      "d  /var/data/framework             0775 root root - -"
      "d  /var/data/framework/sessions    0775 root root - -"
      "d  /var/data/framework/views       0775 root root - -"
      "d  /var/data/framework/cache       0775 root root - -"
      "d  /var/data/logs                  0775 root root - -"
      "Z  /var/data                       0775 root root - -"
    ];

    services.nfs.server.enable = true;
    services.nfs.server.exports = ''
      /var/data    webserver(rw,nohide,insecure,no_subtree_check)
    '';

    systemd.services.nfs-server = {
      after = [ "systemd-tmpfiles-setup.service" ];
      wants = [ "systemd-tmpfiles-setup.service" ];
    };
  };
  */
}
