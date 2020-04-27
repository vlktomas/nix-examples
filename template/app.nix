{
  # dependencies
  stdenv, fetchurl, nix-gitignore, someDependency,

  # args
  localFiles ? false
}:

stdenv.mkDerivation rec {

  pname = "example";
  version = "1.0";

  # run-time dependencies (but can be used also as build-time dependency, because of linker)
  # for example C library or Python interpreter
  buildInputs = [ someDependency ];

  # build-time only dependencies
  # for example gcc, pkgconfig, autoreconfHook, makeWrapper, intltool, bison, flex, ...
  nativeBuildInputs = [];

  # run-time dependencies propagated to other dependent derivations on this derivation
  # for example Python library dependent on another Python library
  # Python program using some library is dependent also on all dependencies of this libraries
  propagatedBuildInputs = [];

  # build-time dependencies propagated to other dependent derivations on this derivation
  # I don't know any example
  propagatedNativeBuildInputs = [];

  # for cross-compile see:
  # https://nixos.wiki/wiki/Cross_Compiling
  # https://nixos.org/nixpkgs/manual/#chap-cross

  src = (
    if localFiles then
      # this will copy all files in current directory to Nix store every time you build this derivation,
      # because of changing result symlink
      #./.

      # so you should filter out the result symlink
      #builtins.filterSource (path: type: baseNameOf path != "result") ./.;

      # if your project contains .gitignore file, you can utilize it to filter out also another unwanted files
      #nix-gitignore.gitignoreSource [ "result" ] ./.

      # but source files are stored in Nix store with project folder name
      # if project folder is renamed, derivation must be rebuilt
      # see https://github.com/NixOS/nix/issues/1305
      # if you do not want this behaviour, you must rename the path
      # (you can also use stdenv.lib.cleanSourceWith instead of builtins.path)
      #let
      #  root = ./.;
      #  gitignoreFilter = nix-gitignore.gitignoreFilterPure (_: _: true) (nix-gitignore.withGitignoreFile [ "result" ] root) root;
      #in
      #  builtins.path {
      #    name = "source";
      #    path = root;
      #    filter = gitignoreFilter;
      #  }

      # another option is to use function fetchGit, but examples in this repostiory do not have own .git folder
      # so fetchGit function cannot be used, but if you can, you should use it instead of nix-gitignore
      builtins.fetchGit { url = ./.; }
    else
      fetchurl {
        url = "https://example.com";
        # if you do not known hash when writing nix expression, you can easily fake it
        # after first run, right hash is printed out
        sha256 = stdenv.lib.fakeSha256;
      }
  );

  # specify configurePhase, buildPhase, ...

  # specify output of derivation
  installPhase =
    ''
      mkdir -p $out/bin
      # copy binary to $out/bin
    '';

  # provide some package attributes, for example executable name
  passthru = {
    executable = pname;
  };

  meta = with stdenv.lib; {
    description = "Example program";
    longDescription = ''
      The Example program with
      long decription.
    '';
    homepage = https://example.com/;
    license = licenses.gpl3Plus;
    # maintainers are registred in Nixpkgs repository
    maintainers = [];
    platforms = platforms.all;
  };
}

