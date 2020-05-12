{
  # dependencies
  stdenv, fetchurl, nix-gitignore, runCommand, jdk11, adoptopenjdk-jre-hotspot-bin-11, maven, makeWrapper,

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

  mavenJdk11Wrapped = runCommand "maven-wrapped" {
      buildInputs = [ makeWrapper mavenJdk11 ];
    } ''
      mkdir $out
      # Link every top-level folder from maven to our new target
      ln -s ${mavenJdk11}/* $out
      # Except the bin folder
      rm $out/bin
      mkdir $out/bin
      # We create the bin folder ourselves and link every binary in it
      ln -s ${mavenJdk11}/bin/* $out/bin
      # Except the mvn binary
      rm $out/bin/mvn
      # Because we create this ourself, by creating a wrapper
      makeWrapper ${mavenJdk11}/bin/mvn $out/bin/mvn --add-flags "--global-settings settings.xml"
    '';

  makeMvnSettingsCommand = (localRepository: ''
      cat > settings.xml <<- EOM
        <settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
          <localRepository>${localRepository}</localRepository>
        </settings>
      EOM
    '');

  mvnDependencyGoOfflineOutput = stdenv.mkDerivation rec {
    name = "mvn-dependency-resolve";

    buildInputs = [ mavenJdk11Wrapped ];

    src = (
      if localFiles then
        builtins.filterSource (path: type: baseNameOf path == "pom.xml") ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    configurePhase =
      makeMvnSettingsCommand "$out";

    installPhase = ''
      mkdir -p $out
      mvn dependency:go-offline -Dmaven.repo.local="$out" --update-snapshots
      find $out -name _maven.repositories -exec rm -v {} \;
      find $out -name _remote.repositories -exec rm -v {} \;
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "1z90ydr0pfklybcg6lf894yb5nv703c82i2scfal85a2dbywn5ka";
  };
in
  stdenv.mkDerivation rec {
    inherit pname version;

    nativeBuildInputs = [ jdk11 makeWrapper mavenJdk11Wrapped ];
    buildInputs = [ adoptopenjdk-jre-hotspot-bin-11 ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    configurePhase =
      makeMvnSettingsCommand mvnDependencyGoOfflineOutput;

    buildPhase = ''
      # property project.build.outputTimestamp is supported in maven-jar-plugin as of 3.2.0,
      # in older versions produced JAR contains timestamps and therefore is not reproducible
      # morover we must update timestamp of pom.xml, because jre cannot load jar files where the modified day or month is 0
      touch pom.xml
      mvn package --no-snapshot-updates --offline -Dproject.build.outputTimestamp=1970-01-01T00:00:00Z
    '';

    installPhase = ''
      mkdir -p $out/share/java
      cp target/pi-1.0.jar $out/share/java/pi-1.0.jar
    '';

    passthru = {
      m2 = mvnDependencyGoOfflineOutput;
      inherit makeMvnSettingsCommand;
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
