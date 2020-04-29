{
  # dependencies
  # The expression should take pythonPackages as one of the arguments,
  # which guarantees that packages belong to the same set.
  stdenv, fetchurl, nix-gitignore, python3Packages,

  # args
  localFiles ? false
}:

python3Packages.buildPythonApplication rec {

  pname = "server";
  version = "1.0";

  propagatedBuildInputs = with python3Packages; [ rpyc hellolib answerlib ];

  src = (
    if localFiles then
      nix-gitignore.gitignoreSourcePure [ "result" ] ./.
    else
      fetchurl {
        url = "https://example.com";
        sha256 = stdenv.lib.fakeSha256;
      }
  );

  doCheck = false;

  passthru = {
    executable = pname;
  };

  meta = with stdenv.lib; {
    description = "Simple RPC server";
    longDescription = ''
      Simple RPC server which exposes functions to get hello greeting
      and answer to the ultimate question.
    '';
    homepage = https://example.com/;
    license = licenses.gpl3Plus;
    maintainers = [];
    platforms = platforms.all;
  };
}
