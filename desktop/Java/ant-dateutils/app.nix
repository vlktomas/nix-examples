{
  # dependencies
  stdenv, fetchurl, nix-gitignore, jdk, jre, ant, makeWrapper,

  # args
  localFiles ? false
}:

stdenv.mkDerivation rec {
  pname = "ant-dateutils";
  version = "1.0";

  nativeBuildInputs = [ jdk ant makeWrapper ];
  buildInputs = [ jre ];

  src = (
    if localFiles then
      nix-gitignore.gitignoreSource [ "result" ] ./.
    else
      fetchurl {
        url = "http://www.mkyong.com/wp-content/uploads/2014/10/AntDateUtils.zip";
        sha256 = "0ssi1wpaf7plaswqqjwigppsg5fyh99vdlb9kzl7c9lng89ndq1i";
      }
  );

  buildPhase = "ant";

  installPhase =
    ''
      mkdir -p $out/bin
      mkdir -p $out/share/java
      cp dist/* $out/share/java/
      makeWrapper ${jre}/bin/java $out/bin/${pname} --add-flags "-jar $out/share/java/DateUtils.jar"
    '';

  passthru = {
    executable = pname;
  };

  meta = with stdenv.lib; {
    description = "Java Ant example";
    longDescription = ''
      The date-utils program which demonstrate building Java project with Ant
    '';
    homepage = https://exmple.com/;
    license = licenses.gpl3Plus;
    maintainers = [];
    platforms = platforms.all;
  };
}
