{ stdenv, fetchurl, runCommand, jdk11, adoptopenjdk-jre-hotspot-bin-11, maven, makeWrapper, nix-gitignore, lib, fetchSources ? true }:

let

  url = "https://example.com";

  sha256 = "0ssi1wpaf7plaswqqjwigppsg5fyh99vdlb9kzl7c9lng89ndq1i"; # bad hash

  mavenJdk11 = maven.overrideAttrs (oldAttrs: {
    jdk = jdk11; 
  });

  mavenJdk11Wrapped = runCommand "maven-wrapped" {
      buildInputs = [ makeWrapper mavenJdk11 ];
    } ''
      mkdir $out
      # Link every top-level folder from pkgs.hello to our new target
      ln -s ${mavenJdk11}/* $out
      # Except the bin folder
      rm $out/bin
      mkdir $out/bin
      # We create the bin folder ourselves and link every binary in it
      ln -s ${mavenJdk11}/bin/* $out/bin
      # Except the hello binary
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
      if fetchSources then
        fetchurl {
          inherit url sha256;
        }
      else
        builtins.filterSource (path: type: baseNameOf path == "pom.xml") ./.
    );

    configurePhase =
      makeMvnSettingsCommand "$out";

    installPhase =
      ''
        mvn dependency:go-offline
        # download surefire-junit-platform which is not explicitly defined as dependency
        mvn dependency:get -Dartifact=org.apache.maven.surefire:surefire-junit-platform:2.22.2
      '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "19mkc9mwf07xa713bwvlwzfk00493kag4rwwgsqbjjxyqw6xwvgv";
  };
in
  stdenv.mkDerivation rec {
    pname = "spring-boot";
    version = "1.0";

    nativeBuildInputs = [ jdk11 makeWrapper mavenJdk11Wrapped ];

    src = (
      if fetchSources then
        fetchurl {
          inherit url sha256;
        }
      else
        nix-gitignore.gitignoreSource [ "*.nix" "result" ] ./.
    );

    configurePhase =
      makeMvnSettingsCommand mvnDependencyGoOfflineOutput;

    # TODO update example to spring boot 2.2.3 or 2.2:4 or 2.2.5 where maven-jar-plugin is updated to 3.2.0 and check that jar contains files with right timestamps
    buildPhase =
      ''
        # property project.build.outputTimestamp is supported in maven-jar-plugin as of 3.2.0, 
        # in older versions produced JAR contains timestamps and therefore is not reproducible
        # morover we must update timestamp of pom.xml, because jre cannot load jar files where the modified day or month is 0
        touch pom.xml
        mvn package -Dproject.build.outputTimestamp=1970-01-01T00:00:00Z
      '';

    installPhase =
      ''
        mkdir -p $out/share/java
        cp target/demo-0.0.1-SNAPSHOT.jar $out/share/java/demo-0.0.1-SNAPSHOT.jar
        mkdir -p $out/bin
        makeWrapper ${adoptopenjdk-jre-hotspot-bin-11}/bin/java $out/bin/spring-boot --add-flags "-jar $out/share/java/demo-0.0.1-SNAPSHOT.jar"
      '';

    passthru = {
      m2 = mvnDependencyGoOfflineOutput;
      inherit makeMvnSettingsCommand;
    };

    meta = with stdenv.lib; {
      description = "";
      longDescription = "";
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [ ];
      platforms = platforms.all;
    };
  }

