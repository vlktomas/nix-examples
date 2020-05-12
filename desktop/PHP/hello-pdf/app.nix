{
  # dependencies
  stdenv, fetchurl, nix-gitignore, php, phpPackages, makeWrapper,

  # args
  localFiles ? false
}:

let

  pname = "hello-pdf";
  version = "1.0";

  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    nativeBuildInputs = [ phpPackages.composer ];

    src = (
      if localFiles then
        builtins.filterSource (path: type: baseNameOf path == "composer.json" || baseNameOf path == "composer.lock") ./.
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
    outputHash = "1hallv8j75x8m90rddw8xal7a50svxs2m0mmhfsp38ajgmm92xy1";
  };

in

  stdenv.mkDerivation rec {

    inherit pname version;

    nativeBuildInputs = [ phpPackages.composer makeWrapper ];
    propagatedBuildInputs = [ php deps ];

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
      makeWrapper ${php}/bin/php $out/bin/${pname} --add-flags "$out/share/php/${pname}/index.php"
    '';

    passthru = {
      inherit deps;
      executable = pname;
    };

    meta = with stdenv.lib; {
      description = "Hello world PDF";
      longDescription = "Program which creates PDF with 'hello world'";
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

