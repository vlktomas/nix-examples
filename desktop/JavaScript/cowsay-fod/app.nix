{
  # dependencies
  stdenv, fetchurl, nix-gitignore, nodejs-10_x, nodePackages, makeWrapper,

  # args
  localFiles ? false
}:

let

  pname = "cowsay";
  version = "1.4.0";

  url = "https://github.com/piuccio/cowsay/archive/v1.4.0.tar.gz";
  sha256 = "0hhsdg5hp7ihrm9hza6md84z401yjvy37dlhqgz5v0ydbwjan0jb";

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    nativeBuildInputs = [ nodejs-10_x nodePackages.npm ];

    src = (
      if localFiles then
        builtins.filterSource (path: type: baseNameOf path == "package.json" || baseNameOf path == "package-lock.json") ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    buildPhase = ''
      export npm_config_cache=$(mktemp -d)
      npm install
    '';

    installPhase = ''
      mkdir -p $out
      cp -R node_modules/* $out
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "1xvvkxlcjrkc3ynmfkidv8jy38s9mxwla0j7a1xgxbx79pg8fq1s";
  };

in

  stdenv.mkDerivation rec {

    inherit pname version;

    nativeBuildInputs = [ makeWrapper ];
    propagatedBuildInputs = [ nodejs-10_x deps ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    # FIXME we must copy node_modules dir
    configurePhase =
      ''
        #ln -s ${deps} node_modules
        mkdir node_modules
        cp -R ${deps}/* node_modules
        chmod -R u+w node_modules
      '';

    installPhase =
      ''
        mkdir -p $out/lib/node_modules/${pname}
        cp -R . $out/lib/node_modules/${pname}
        mkdir -p $out/bin
        makeWrapper ${nodejs-10_x}/bin/node $out/bin/${pname} --add-flags "$out/lib/node_modules/${pname}/cli.js"
      '';

    passthru = {
      inherit deps;
      executable = pname;
    };

    meta = with stdenv.lib; {
      description = "Cowsay";
      longDescription = "Program which prints cow saying some words.";
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

