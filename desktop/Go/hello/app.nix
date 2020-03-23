{
  # dependencies
  stdenv, fetchurl, nix-gitignore, buildGoModule,

  # args
  localFiles ? false
}:

buildGoModule rec {

  name = "hello-${version}";
  version = "1.0";

  src = (
    if localFiles then
      nix-gitignore.gitignoreSource [ "result" ] ./.
    else
      fetchurl {
        url = "https://example.com";
        sha256 = stdenv.lib.fakeSha256;
      }
  );

  modSha256 = "1ggp6xhhlixihjx37v5j9gd3sa1gymqrglf9c3j1pwfnym1k99y3";

  subPackages = [ "." ];

  meta = with stdenv.lib; {
    description = "Hello world example in Go";
    homepage = https://blog.golang.org/using-go-modules;
    license = licenses.asl20;
    platforms = platforms.all;
  };
}

