{
  # dependencies
  stdenv, fetchurl, nix-gitignore, php, phpPackages, makeWrapper,

  # args
  localFiles ? false
}:

let

  pname = "laravel-cli";
  version = "1.0";

  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    nativeBuildInputs = [ phpPackages.composer ];

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

in

  stdenv.mkDerivation rec {

    inherit pname version;

    # we copy vendor folder, so deps is build-only dependency
    nativeBuildInputs = [ phpPackages.composer makeWrapper deps ];
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
    '';

    buildPhase = ''
      composer dump-autoload --optimize
    '';

    installPhase = ''
      mkdir -p $out/share/php/${pname}
      cp -R . $out/share/php/${pname}
      mkdir -p $out/bin
      makeWrapper ${php}/bin/php $out/bin/${pname} --add-flags "$out/share/php/${pname}/artisan"
    '';

    passthru = {
      inherit deps;
      executable = pname;
    };

    meta = with stdenv.lib; {
      description = "Laravel CLI app";
      longDescription = "The example of Laravel CLI app";
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

