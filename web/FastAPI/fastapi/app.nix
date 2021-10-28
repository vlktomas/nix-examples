{
  # dependencies
  stdenv, lib, fetchurl, poetry2nix, python39,
  # args
  localFiles ? false
}:

poetry2nix.mkPoetryApplication rec {

  projectDir = (
    if localFiles then
      ./.
    else
      fetchurl {
        url = "https://example.com";
        sha256 = lib.fakeSha256;
      }
  );

  python = python39;

  meta = with lib; {
    description = "FastAPI";
    longDescription = "Example of FastAPI website";
    homepage = https://example.com/;
    license = licenses.gpl3Plus;
    maintainers = [];
    platforms = platforms.all;
  };
}

