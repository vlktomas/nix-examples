{
  # dependencies
  stdenv, fetchurl, fetchgit, nix-gitignore, utillinux, runCommand, writeTextFile, writeText, makeWrapper, darwin,
  python2, php, phpPackages, nodejs-10_x, nodePackages,

  # args
  localFiles ? false,
  appKey ? "",
  appStoragePath ? "storage",
  dbHost ? "127.0.0.1",
  dbPort ? 3306,
  dbSocket ? "",
  dbName ? "example",
  dbUsername ? "root",
  dbPassword ? ""
}:

let

  pname = "laravel";
  version = "1.0";

  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    buildInputs = [ phpPackages.composer ];

    src = (
      if localFiles then
        # we must include database folder because of classmap in composer.json
        nix-gitignore.gitignoreSourcePure [
          "*"
          "!composer.json"
          "!composer.lock"
          "!database"
          "!database/seeds/"
          "!database/factories/"
        ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    buildPhase = ''
      composer install --no-autoloader
    '';

    installPhase = ''
      mkdir -p $out
      cp -R vendor/* $out
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "1gbd7qhs0l3d74x7ynid5rxvi6cnf6mnzk0aia1v5da9ijv86j8i";
  };

  node2nixOutput = runCommand "node2nix"
    {
      src = (
        if localFiles then
          builtins.filterSource (path: type: baseNameOf path == "package.json" || baseNameOf path == "package-lock.json") ./.
        else
          fetchurl {
            inherit url sha256;
          }
      );

      buildInputs = [ nodePackages.node2nix ];
    }
    ''
      mkdir -p $out
      node2nix --development -l $src/package-lock.json --input $src/package.json \
        --output $out/node-packages.nix --composition $out/default.nix --node-env $out/node-env.nix
    '';

  nodeEnv = import "${node2nixOutput}/node-env.nix" {
    inherit stdenv python2 utillinux runCommand writeTextFile;
    nodejs = nodejs-10_x;
    libtool = if stdenv.isDarwin then darwin.cctools else null;
  };

  nodeApp = import "${node2nixOutput}/node-packages.nix" {
    inherit fetchurl fetchgit;
    inherit nodeEnv;
  };

  nodePackage = (nodeApp.package.override {
    src = (
      if localFiles then
        builtins.filterSource (path: type: baseNameOf path == "package.json" || baseNameOf path == "package-lock.json") ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );
  });

  envFile = writeText "${pname}-${version}-env" ''
    APP_NAME=Laravel
    APP_ENV=local
    APP_KEY=${toString appKey}
    APP_DEBUG=true
    APP_URL=http://localhost
    APP_STORAGE_PATH=${toString appStoragePath}

    LOG_CHANNEL=stack

    DB_CONNECTION=mysql
    DB_HOST=${toString dbHost}
    DB_PORT=${toString dbPort}
    DB_SOCKET=${toString dbSocket}
    DB_DATABASE=${toString dbName}
    DB_USERNAME=${toString dbUsername}
    DB_PASSWORD=${toString dbPassword}

    BROADCAST_DRIVER=log
    CACHE_DRIVER=file
    QUEUE_CONNECTION=sync
    SESSION_DRIVER=file
    SESSION_LIFETIME=120

    REDIS_HOST=127.0.0.1
    REDIS_PASSWORD=null
    REDIS_PORT=6379

    MAIL_DRIVER=smtp
    MAIL_HOST=smtp.mailtrap.io
    MAIL_PORT=2525
    MAIL_USERNAME=null
    MAIL_PASSWORD=null
    MAIL_ENCRYPTION=null

    AWS_ACCESS_KEY_ID=
    AWS_SECRET_ACCESS_KEY=
    AWS_DEFAULT_REGION=us-east-1
    AWS_BUCKET=

    PUSHER_APP_ID=
    PUSHER_APP_KEY=
    PUSHER_APP_SECRET=
    PUSHER_APP_CLUSTER=mt1

    MIX_PUSHER_APP_KEY="''${PUSHER_APP_KEY}"
    MIX_PUSHER_APP_CLUSTER="''${PUSHER_APP_CLUSTER}"
  '';

in

  stdenv.mkDerivation rec {

    inherit pname version;

    # we copy vendor folder, so deps is build-only dependency
    nativeBuildInputs = [ phpPackages.composer makeWrapper nodejs-10_x nodePackage deps ];
    propagatedBuildInputs = [ php ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    configurePhase = ''
      mkdir -p vendor/composer
      cp ${deps}/composer/* vendor/composer/
      shopt -s extglob
      ln -s ${deps}/!(composer) vendor/
      ln -s ${nodePackage}/lib/node_modules/laravel-node-dependencies/node_modules node_modules
    '';

    buildPhase = ''
      # create temp storage in order to use composer dump-autoload command
      export TEMP=$(mktemp -d)
      mkdir -p $TEMP/app
      mkdir -p $TEMP/framework/sessions $TEMP/framework/views $TEMP/framework/cache
      mkdir -p $TEMP/logs
      cp .env.example .env
      sed -i "s:APP_STORAGE_PATH=.*:APP_STORAGE_PATH=$TEMP:" .env
      composer dump-autoload --optimize
      rm .env
      ln -s ${envFile} .env
      #php artisan key:generate
      #sed -i "s:APP_KEY=.*:APP_KEY=${toString appKey}:" .env
      #sed -i "s:APP_STORAGE_PATH=.*:APP_STORAGE_PATH=${toString appStoragePath}:" .env
      #sed -i "s:DB_HOST=.*:DB_HOST=${toString dbHost}:" .env
      #sed -i "s:DB_PORT=.*:DB_PORT=${toString dbPort}:" .env
      #sed -i "s:DB_SOCKET=.*:DB_SOCKET=${toString dbSocket}:" .env
      #sed -i "s:DB_DATABASE=.*:DB_DATABASE=${toString dbName}:" .env
      #sed -i "s:DB_USERNAME=.*:DB_USERNAME=${toString dbUsername}:" .env
      #sed -i "s:DB_PASSWORD=.*:DB_PASSWORD=${toString dbPassword}:" .env
      #npm run prod
      export NODE_ENV=production
      node node_modules/webpack/bin/webpack.js --no-progress --hide-modules --config=node_modules/laravel-mix/setup/webpack.config.js
    '';

    installPhase = ''
      mkdir -p $out/share/php/${pname}
      cp -R . $out/share/php/${pname}
      mkdir -p $out/bin
      makeWrapper ${php}/bin/php $out/bin/${pname} --add-flags "$out/share/php/${pname}/artisan"
    '';

    passthru = {
      phpDeps = deps;
      nodePackage = nodePackage;
      nodeTarball = nodeApp.tarball;
      nodeShell = nodeApp.shell;
    };

    meta = with stdenv.lib; {
      description = "Laravel";
      longDescription = "Example of Laravel website";
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

