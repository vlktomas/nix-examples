# inspired by /nixos/modules/services/mail/sympa.nix and /nixos/modules/services/web-apps/mediawiki.nix

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.laravel;
  user = "laravel";
  group = config.services.httpd.group;
  pkg = import ./default.nix {
    appKey = cfg.app.key;
    appStoragePath = cfg.app.storage.path;
    dbHost = cfg.database.host;
    dbPort = cfg.database.port;
    dbSocket = cfg.database.socket;
    dbName = cfg.database.name;
    dbUsername = cfg.database.username;
    dbPassword = cfg.database.password;
  };

in

  {

    # interface

    options.services.laravel = with types; {

      enable = mkEnableOption "Laravel example";

      hostName = mkOption {
        type = str;
        default = "localhost";
        description = "Web hostname.";
      };

      virtualHost = mkOption {
        type = nullOr (submodule (import <nixpkgs/nixos/modules/services/web-servers/apache-httpd/vhost-options.nix>));
        example = literalExample ''
          {
            hostName = "example.org";
            enableSSL = true;
            adminAddr = "webmaster@example.org";
            sslServerCert = "/var/lib/acme/example.org/full.pem";
            sslServerKey = "/var/lib/acme/example.org/key.pem";
          }
        '';
        default = null;
        description = ''
          Apache configuration can be done by adapting <option>services.httpd.virtualHosts</option>.
          See <xref linkend="opt-services.httpd.virtualHosts"/> for further information.
        '';
      };

      database = {

        createLocally = mkOption {
          type = bool;
          default = true;
          description = "Whether database should declared by module.";
        };

        host = mkOption {
          type = str;
          default = "127.0.0.1";
          description = "Database host address.";
        };

        socket = mkOption {
          type = nullOr path;
          default = if cfg.database.createLocally then "/run/mysqld/mysqld.sock" else null;
          defaultText = "/run/mysqld/mysqld.sock";
          description = "Path to the unix socket file to use for authentication.";
        };

        port = mkOption {
          type = port;
          default = 3306;
          description = "Database port.";
        };

        name = mkOption {
          type = str;
          default = "example";
          description = "Database name.";
        };

        username = mkOption {
          type = str;
          default = "laravel";
          description = "Database user.";
        };

        password = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Database password.  Use <literal>passwordFile</literal> to avoid this
            being world-readable in the <literal>/nix/store</literal>.
          '';
        };

        passwordFile = mkOption {
          type = nullOr path;
          default = null;
          example = "/run/keys/laravel-dbpassword";
          description = ''
            A file containing the password corresponding to
            <option>database.username</option>.
          '';
        };

        seed = mkOption {
          type = bool;
          default = false;
          description = "Whether database should be seeded.";
        };
      };

      app = {

        storage = {

          createLocally = mkOption {
            type = bool;
            default = true;
            description = "Whether storage should declared by module.";
          };

          path = mkOption {
            type = str;
            default = "/var/laravel";
            description = "Path to Laravel storage location.";
          };
        };

        key = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            App key.  Use <literal>keyFile</literal> to avoid this
            being world-readable in the <literal>/nix/store</literal>.
          '';
        };

        keyFile = mkOption {
          type = nullOr path;
          default = null;
          example = "/run/keys/laravel";
          description = "A file containing the app key.";
        };
      };
    };

    # implementation

    config = mkIf cfg.enable {

      assertions = [
        {
          assertion = !(cfg.app.key != null && cfg.app.keyFile != null);
          message = "Please specify no more than one of key or keyFile";
        }
        {
          assertion = !(cfg.database.password != null && cfg.database.passwordFile != null);
          message = "Please specify no more than one of password or passwordFile";
        }
        {
          assertion = cfg.database.createLocally -> cfg.database.username == user;
          message = "services.laravale.database.username must be set to ${user} if services.laravel.database.createLocally is set true";
        }
        { assertion = cfg.database.createLocally -> cfg.database.socket != null;
          message = "services.mediawiki.database.socket must be set if services.laravel.database.createLocally is set to true";
        }
        {
          assertion = cfg.database.createLocally -> cfg.database.password == null;
          message = "a password cannot be specified if services.laravel.database.createLocally is set to true";
        }
      ];

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      systemd.tmpfiles.rules = mkIf cfg.app.storage.createLocally [
        "d  ${cfg.app.storage.path}                       0775 ${user} ${group} - -"
        "d  ${cfg.app.storage.path}/app                   0775 ${user} ${group} - -"
        "d  ${cfg.app.storage.path}/framework             0775 ${user} ${group} - -"
        "d  ${cfg.app.storage.path}/framework/sessions    0775 ${user} ${group} - -"
        "d  ${cfg.app.storage.path}/framework/views       0775 ${user} ${group} - -"
        "d  ${cfg.app.storage.path}/framework/cache       0775 ${user} ${group} - -"
        "d  ${cfg.app.storage.path}/logs                  0775 ${user} ${group} - -"
        "Z  ${cfg.app.storage.path}                       0775 ${user} ${group} - -"
      ];

      services.httpd = {
        enable = true;
        enablePHP = true;
        adminAddr = "admin@${cfg.hostName}";
        extraModules = [ "rewrite" ];
        virtualHosts =
          let
            defaultVirtualHost = rec {
              forceSSL = true;
              enableACME = true;
              documentRoot = "${pkg}/share/php/laravel/public";
              extraConfig =
                (optionalString (cfg.app.keyFile != null)
                ''
                PassEnv APP_KEY
                '') +
                (optionalString (cfg.database.passwordFile != null)
                ''
                PassEnv DB_PASSWORD
                '') +
                ''
                <Directory "${documentRoot}">
                    Options Indexes FollowSymLinks
                    AllowOverride All
                    Require all granted
                </Directory>
                <IfModule dir_module>
                  DirectoryIndex index.html index.php
                </IfModule>
              '';
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

      services.mysql = mkIf cfg.database.createLocally {
        enable = true;
        ensureDatabases = [ cfg.database.name ];
        ensureUsers = [
          {
            name = cfg.database.username;
            ensurePermissions = {
              "${cfg.database.name}.*" = "ALL PRIVILEGES";
            };
          }
        ];
        package = pkgs.mariadb;
      };

      # we must use EnvronmentFile in systemd units, because ExecStartPre is different process from ExecStart and
      # modifying ExecStart of httpd service is awful hack. So keys must be in specific format.

      systemd.services.httpd = {
        after =
          optional cfg.database.createLocally "mysql.service" ++
          optional cfg.database.createLocally "systemd-tmpfiles-setup.service";
        wants =
          optional cfg.database.createLocally "mysql.service" ++
          optional cfg.database.createLocally "systemd-tmpfiles-setup.service";
        /*
        preStart =
          optionalString (cfg.app.keyFile != null)
          ''
          export APP_KEY=$(${pkgs.coreutils}/bin/cat ${cfg.app.keyFile})
          '' +
          optionalString (cfg.database.passwordFile != null)
          ''
          export DB_PASSWORD=$(${pkgs.coreutils}/bin/cat ${cfg.database.passwordFile})
          '';
        */
        serviceConfig = mkIf (cfg.app.keyFile != null || cfg.database.passwordFile != null) {
          EnvironmentFile =
            optional (cfg.app.keyFile != null) cfg.app.keyFile ++
            optional (cfg.database.passwordFile != null) cfg.database.passwordFile;
          PassEnvironment =
            optional (cfg.app.keyFile != null) "APP_KEY" ++
            optional (cfg.database.passwordFile != null) "DB_PASSWORD";
        };
      };

      systemd.timers.laravel-cron = {
        wantedBy = [ "timers.target" ];
        timerConfig.OnBootSec = "1m";
        timerConfig.OnUnitActiveSec = "1m";
        timerConfig.Unit = "laravel-cron.service";
      };

      systemd.services.laravel-cron = {
        script = ''
          ${pkgs.php}/bin/php ${pkg}/share/php/laravel/artisan schedule:run
        '';
        serviceConfig = {
          Type = "oneshot";
          User = user;
          EnvironmentFile =
            optional (cfg.app.keyFile != null) cfg.app.keyFile ++
            optional (cfg.database.passwordFile != null) cfg.database.passwordFile;
          PassEnvironment =
            optional (cfg.app.keyFile != null) "APP_KEY" ++
            optional (cfg.database.passwordFile != null) "DB_PASSWORD";
        };
      };

      systemd.services.laravel-database-migration = {
        description = "Run Laravel migrations";
        wantedBy = [ "multi-user.target" ];
        after =
          optional cfg.database.createLocally "mysql.service" ++
          optional cfg.app.storage.createLocally "systemd-tmpfiles-setup.service";
        wants =
          optional cfg.database.createLocally "mysql.service" ++
          optional cfg.app.storage.createLocally "systemd-tmpfiles-setup.service";
        path = [ pkgs.php ];
        script = ''
          set -e
          ${pkgs.php}/bin/php ${pkg}/share/php/laravel/artisan migrate
        '';
        serviceConfig = {
          Type = "oneshot";
          User = user;
          EnvironmentFile =
            optional (cfg.app.keyFile != null) cfg.app.keyFile ++
            optional (cfg.database.passwordFile != null) cfg.database.passwordFile;
          PassEnvironment =
            optional (cfg.app.keyFile != null) "APP_KEY" ++
            optional (cfg.database.passwordFile != null) "DB_PASSWORD";
        };
      };

      systemd.services.laravel-database-seed = mkIf cfg.database.seed {
        description = "Run Laravel migrations and seeders";
        wantedBy = [ "multi-user.target" ];
        after =
          optional cfg.database.createLocally "mysql.service" ++
          optional cfg.app.storage.createLocally "systemd-tmpfiles-setup.service";
        wants =
          optional cfg.database.createLocally "mysql.service" ++
          optional cfg.app.storage.createLocally "systemd-tmpfiles-setup.service";
        path = [ pkgs.php ];
        script = ''
          set -e
          ${pkgs.php}/bin/php ${pkg}/share/php/laravel/artisan db:seed
        '';
        serviceConfig = {
          Type = "oneshot";
          User = user;
          EnvironmentFile =
            optional (cfg.app.keyFile != null) cfg.app.keyFile ++
            optional (cfg.database.passwordFile != null) cfg.database.passwordFile;
          PassEnvironment =
            optional (cfg.app.keyFile != null) "APP_KEY" ++
            optional (cfg.database.passwordFile != null) "DB_PASSWORD";
        };
      };

      users.users.${user}.group = group;

    };
  }

