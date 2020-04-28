{
  # dependencies
  stdenv, fetchurl, fetchgit, nix-gitignore, darwin, nodejs-10_x, nodePackages, python2, utillinux, runCommand, writeTextFile,

  # args
  localFiles ? false
}:

let

  url = "https://github.com/piuccio/cowsay/archive/v1.4.0.tar.gz";
  sha256 = "0hhsdg5hp7ihrm9hza6md84z401yjvy37dlhqgz5v0ydbwjan0jb";

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

      nativeBuildInputs = [ nodePackages.node2nix ];
    }
    ''
      mkdir -p $out
      node2nix -l $src/package-lock.json --input $src/package.json \
        --output $out/node-packages.nix --composition $out/default.nix --node-env $out/node-env.nix
    '';

  nodeEnv = import "${node2nixOutput}/node-env.nix" {
    inherit stdenv python2 utillinux runCommand writeTextFile;
    nodejs = nodejs-10_x;
    libtool = if stdenv.isDarwin then darwin.cctools else null;
  };

  app = import "${node2nixOutput}/node-packages.nix" {
    inherit fetchurl fetchgit;
    inherit nodeEnv;
  };

in

  (app.package.override {

    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

  }).overrideAttrs (oldAttrs: rec {

    pname = "cowsay";
    version = "1.4.0";
    name = "${pname}-${version}";

    passthru = {
      tarball = app.tarball;
      shell = app.shell;
      executable = pname;
    };

  })
