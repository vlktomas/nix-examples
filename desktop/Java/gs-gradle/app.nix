{
  # dependencies
  stdenv, fetchurl, nix-gitignore, jdk, jre, gradle, perl, writeText, makeWrapper,

  # args
  localFiles ? false
}:

let

  pname = "gs-gradle";
  version = "0.1.0";
  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    nativeBuildInputs = [ gradle perl ];

    src = (
      if localFiles then
        builtins.filterSource (path: type: baseNameOf path == "build.gradle") ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    buildPhase = ''
      export GRADLE_USER_HOME=$(mktemp -d);
      # add task to download dependencies to build.gradle
      cat <<- EOM >> build.gradle

      task downloadDependencies(type: Exec) {
          configurations.testRuntime.files
          commandLine 'echo', 'Downloaded all dependencies'
      }
      EOM
      gradle --no-daemon downloadDependencies
    '';

    # Mavenize dependency paths
    # e.g. org.codehaus.groovy/groovy/2.4.0/{hash}/groovy-2.4.0.jar -> org/codehaus/groovy/groovy/2.4.0/groovy-2.4.0.jar
    installPhase = ''
      find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\)' \
        | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
        | sh
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "1ykdjy6m5dnqb9qav0mz3a4dd4zf7la4qqmph1b0qippqjwc2dmx";
  };

  gradleInit = writeText "init.gradle" ''
    logger.lifecycle 'Replacing Maven repositories with ${deps}...'
    gradle.projectsLoaded {
      rootProject.allprojects {
        buildscript {
          repositories {
            clear()
            maven { url '${deps}' }
          }
        }
        repositories {
          clear()
          maven { url '${deps}' }
        }
      }
    }
  '';

in

  stdenv.mkDerivation rec {

    inherit pname version;

    nativeBuildInputs = [ jdk makeWrapper gradle deps ];
    buildInputs = [ jre ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    buildPhase = ''
      export GRADLE_USER_HOME=$(mktemp -d)
      # point to local deps repo
      gradle --offline --no-daemon --info --init-script ${gradleInit} jar
    '';

    installPhase = ''
      mkdir -p $out/share/java
      cp build/libs/${pname}-${version}.jar $out/share/java/${pname}-${version}.jar
      mkdir -p $out/bin
      makeWrapper ${jre}/bin/java $out/bin/${pname} --add-flags "-jar $out/share/java/${pname}-${version}.jar"
    '';

    passthru = {
      inherit deps;
      executable = pname;
    };

    meta = with stdenv.lib; {
      description = "Java Gradle example";
      longDescription = ''
        The gs-gradle program which demonstrate building Java project with Gradle
      '';
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

