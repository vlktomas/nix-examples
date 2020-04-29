{
  # dependencies
  # The expression should take pythonPackages as one of the arguments,
  # which guarantees that packages belong to the same set.
  stdenv, fetchurl, nix-gitignore, python3Packages,

  # args
  localFiles ? false
}:

# for Python library use python3Packages.buildPythonPackage
python3Packages.buildPythonApplication rec {

  pname = "answer";
  version = "1.0";

  propagatedBuildInputs = with python3Packages; [ numpy ];

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
    description = "Answer";
    longDescription = ''
      A program that prints answer to the ultimate question.
    '';
    homepage = https://example.com/;
    license = licenses.gpl3Plus;
    maintainers = [];
    platforms = platforms.all;
  };
}
