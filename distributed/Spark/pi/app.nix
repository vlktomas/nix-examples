{
  # dependencies
  stdenv, fetchurl, nix-gitignore, jdk11, adoptopenjdk-jre-hotspot-bin-11, maven, makeWrapper,

  # args
  localFiles ? false
}:

let
  pname = "pi";
  version = "1.0";
  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  mavenJdk11 = maven.overrideAttrs (oldAttrs: {
    jdk = jdk11;
  });

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    buildInputs = [ mavenJdk11 ];

    src = (
      if localFiles then
        builtins.filterSource (path: type: baseNameOf path == "pom.xml") ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    installPhase = ''
      mkdir -p $out
      mvn dependency:go-offline -Dmaven.repo.local="$out" --update-snapshots
      find $out -name _maven.repositories -exec rm -v {} \;
      find $out -name _remote.repositories -exec rm -v {} \;
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "1vnzwmr2bsk8i7dcmc94ir54v7kgbr7z0nsyalpjrsvkh5vwil2z";
  };
in
  stdenv.mkDerivation rec {
    inherit pname version;

    nativeBuildInputs = [ jdk11 makeWrapper mavenJdk11 deps ];
    buildInputs = [ adoptopenjdk-jre-hotspot-bin-11 ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    buildPhase = ''
      # property project.build.outputTimestamp is supported in maven-jar-plugin as of 3.2.0,
      # in older versions produced JAR contains timestamps and therefore is not reproducible
      # morover we must update timestamp of pom.xml, because jre cannot load jar files where the modified day or month is 0
      touch pom.xml
      mvn package --no-snapshot-updates --offline -Dmaven.repo.local="${deps}" -Dproject.build.outputTimestamp=1970-01-01T00:00:00Z
    '';

    installPhase = ''
      mkdir -p $out/share/java
      cp target/pi-1.0.jar $out/share/java/pi-1.0.jar
    '';

    passthru = {
      inherit deps;
    };

    meta = with stdenv.lib; {
      description = "Spark Pi example";
      longDescription = ''
        Simple Spark example, which computes Pi estimation.
      '';
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }
