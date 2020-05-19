{
  # dependencies
  stdenv, fetchurl, nix-gitignore, texlive,

  # args
  localFiles ? false
}:

let

  texliveCombined = (texlive.combine {
    inherit (texlive) scheme-basic latexmk
      babel-czech blindtext caption cm-super enumitem mathtools microtype multirow mwe;
  });

in

  stdenv.mkDerivation rec {

    pname = "sample-doc";
    version = "1.0";

    buildInputs = [ texliveCombined ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSourcePure [ "result" ] ./.
      else
        fetchurl {
          url = "https://example.com";
          sha256 = stdenv.lib.fakeSha256;
        }
    );

    installPhase = ''
      mkdir -p $out
      cp project.pdf $out/
    '';

    meta = with stdenv.lib; {
      description = "Example LaTeX document";
      longDescription = ''
        The Example LaTeX document built with latexmk.
      '';
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

