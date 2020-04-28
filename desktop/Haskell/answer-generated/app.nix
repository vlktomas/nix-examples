{
  # dependencies
  stdenv, fetchurl, nix-gitignore, runCommand, git, haskell, haskellPackages,

  # args
  localFiles ? false
}:

let

  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  cabal2nixOutput = runCommand "run-cabal2nix"
    {
      src = (
        if localFiles then
          builtins.filterSource (path: type: baseNameOf path == "answer.cabal") ./.
        else
          fetchurl {
            inherit url sha256;
          }
      );
      nativeBuildInputs = [ haskellPackages.cabal2nix git ];
    }
    ''
      cp -pr --reflink=auto -- "$src"/* .
      git init
      cabal2nix . > $out
    '';

  package = haskellPackages.callPackage (import "${cabal2nixOutput}") { };

in

  haskell.lib.overrideCabal package (old: {
    enableSharedExecutables = true;
    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );
    passthru = {
      executable = "answer";
    };

    description = "A program that prints answer to the ultimate question";
    homepage = https://example.com/;
    license = stdenv.lib.licenses.bsd3;
    maintainers = [];
    platforms = stdenv.lib.platforms.all;
  })
