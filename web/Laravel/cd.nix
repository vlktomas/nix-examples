{
  nixpkgsSource ? null,
  localFiles ? true,
  appKeyFile ? builtins.toFile "app-key" "APP_KEY=base64:eFMkq9zwjK42i7qXiN04rTKKWhD5FexWO9zetWawTXg=",
  databasePasswordFile ? builtins.toFile "db-password" "DB_PASSWORD=password",
  storageLocally ? true,
  databaseLocally ? true
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
in
  {

    webserver = {

      nixpkgs.pkgs = pkgs;

      imports = [
        ./module.nix
      ];

      services.laravel = {
        enable = true;
        app.keyFile = appKeyFile;

        app.storage = {

          createLocally = storageLocally;

        } // lib.optionalAttrs (!storageLocally) {

          path = "/mnt/data";
        };

        database = {

          createLocally = databaseLocally;

        } // lib.optionalAttrs (!databaseLocally) {

          host = "dbserver";
          port = 3306;
          name = "example";
          username = "laravel";
          passwordFile = databasePasswordFile;
        };
      };

    } // lib.optionalAttrs (!storageLocally) {

      # when building a VM, filesystems options are overriden and NFS
      # filesystem will not be mounted, so we must use 'mkVMOverride'
      fileSystems = lib.mkVMOverride {
        "/mnt/data" = {
          fsType = "nfs";
          device = "fileserver:/";
          options = [ "vers=4" ];
        };
      };
    };

  } // lib.optionalAttrs (!storageLocally) {

    fileserver = {

      nixpkgs.pkgs = pkgs;

      networking.firewall.allowedTCPPorts = [ 111 2049 4000 4001 20048 ];
      networking.firewall.allowedUDPPorts = [ 111 2049 4000 4001 20048 ];

      systemd.tmpfiles.rules = [
        "d  /export/app                   0777 root root - -"
        "d  /export/framework             0777 root root - -"
        "d  /export/framework/sessions    0777 root root - -"
        "d  /export/framework/views       0777 root root - -"
        "d  /export/framework/cache       0777 root root - -"
        "d  /export/logs                  0777 root root - -"
        "Z  /export                       0777 root root - -"
      ];

      services.nfs.server = {
        enable = true;
        exports = ''
          /export             webserver(insecure,rw,sync,no_subtree_check,no_root_squash,crossmnt,fsid=0)
          /export/app         webserver(nohide,insecure,rw,sync,no_subtree_check,no_root_squash)
          /export/framework   webserver(nohide,insecure,rw,sync,no_subtree_check,no_root_squash)
          /export/logs        webserver(nohide,insecure,rw,sync,no_subtree_check,no_root_squash)
        '';
        lockdPort = 4001;
        statdPort = 4000;
      };

      systemd.services.nfs-server = {
        after = [ "systemd-tmpfiles-setup.service" ];
        wants = [ "systemd-tmpfiles-setup.service" ];
      };
    };

  } // lib.optionalAttrs (!databaseLocally) {

    dbserver = {

      nixpkgs.pkgs = pkgs;

      networking.firewall.allowedTCPPorts = [ 3306 ];

      services.mysql = {
        enable = true;
        initialScript =
          let
            databasePassword = lib.removePrefix "DB_PASSWORD=" (lib.fileContents databasePasswordFile);
          in
            pkgs.writeText "initial-script" ''
              CREATE DATABASE IF NOT EXISTS `example`;
              CREATE USER IF NOT EXISTS 'laravel'@'webserver' IDENTIFIED WITH mysql_native_password;
              ALTER USER 'laravel'@'webserver' IDENTIFIED BY '${databasePassword}';
              GRANT ALL PRIVILEGES ON example.* TO 'laravel'@'webserver';
            '';
        package = pkgs.mariadb;
      };
    };

  }
