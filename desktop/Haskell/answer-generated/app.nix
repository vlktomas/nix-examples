{
  # dependencies
  stdenv, fetchurl, nix-gitignore, runCommand, haskell, haskellPackages,

  # args
  localFiles ? false
}:

let

  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  cabal2nixOutput = runCommand "cabal2nix"
    {
      src = (
        if localFiles then
          builtins.filterSource (path: type: baseNameOf path == "answer.cabal") ./.
        else
          fetchurl {
            inherit url sha256;
          }
      );
      nativeBuildInputs = [ haskellPackages.cabal2nix ];
    }
    ''
      cabal2nix . > $out
    '';

  package = haskellPackages.callPackage cabal2nixOutput;

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
    # TODO passthru
    passthru = {
      executable = "answer";
    };
    # TODO meta
  })

