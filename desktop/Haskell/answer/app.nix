{
  # dependencies
  stdenv, fetchurl, nix-gitignore, mkDerivation, base, protolude,

  # args
  localFiles ? false
}:

mkDerivation rec {

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

  passthru = {
    executable = pname;
  };

  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base protolude ];
  enableSharedExecutables = true;

  description = "A program that prints answer to the ultimate question";
  homepage = https://example.com/;
  license = stdenv.lib.licenses.bsd3;
  maintainers = [];
  platforms = stdenv.lib.platforms.all;
}
