{
  # dependencies
  stdenv, fetchurl, nix-gitignore, mkDerivation, base, protolude,

  # args
  localFiles ? false
}:

mkDerivation {

  pname = "answer";
  version = "0.1.0.0";

  src = (
    if localFiles then
      nix-gitignore.gitignoreSource [ "result" ] ./.
    else
      fetchurl {
        url = "https://example.com";
        sha256 = stdenv.lib.fakeSha256;
      }
  );

  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base protolude ];
  enableSharedExecutables = true;

  license = stdenv.lib.licenses.bsd3;
  # TODO meta
}

