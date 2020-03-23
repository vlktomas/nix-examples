{
  # dependencies
  stdenv, fetchurl, nix-gitignore, androidsdk_9_0, gradle, perl, writeText, makeWrapper,

  # args
  localFiles ? false,
  release ? true
}:

let

  pname = "CardView";
  version = "0.1.0";

  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    nativeBuildInputs = [ gradle perl ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSourcePure [
          "*"
          "!*.gradle"
          "!*.properties"
          "!Application"
          "!Application/build.gradle"
          "!Application/src"
          "!Application/src/main"
          "!Application/src/main/AndroidManifest.xml"
        ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    buildPhase = 
      ''
        export GRADLE_USER_HOME=$(mktemp -d);
        export ANDROID_SDK_ROOT=${androidsdk_9_0}/libexec/android-sdk
        export ANDROID_HOME=${androidsdk_9_0}/libexec
        export ANDROID_SDK_HOME=$(mktemp -d)
        # add task to download dependencies to build.gradle
        cat <<- EOM >> Application/build.gradle

        task downloadDependencies(type: Exec) {
            configurations.implementation.setCanBeResolved(true)
            configurations.api.setCanBeResolved(true)
            configurations.implementation.files
            commandLine 'echo', 'Downloaded all dependencies'
        }
        EOM
        gradle --no-daemon --no-build-cache downloadDependencies
        # fake build to pre-download other deps
        gradle --no-daemon --no-build-cache assembleDebug || true
      '';

    # Mavenize dependency paths
    # e.g. org.codehaus.groovy/groovy/2.4.0/{hash}/groovy-2.4.0.jar -> org/codehaus/groovy/groovy/2.4.0/groovy-2.4.0.jar
    installPhase = 
      ''
        find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\|aar\)' \
          | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
          | sh
      '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "1b9xc8g9vv7d9slvgkdf193739dw7frs49wv32sjf9qsvwvyrh99";
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

    nativeBuildInputs = [ androidsdk_9_0 gradle deps ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    # FIXME gradle creates aapt2 in GRADLE_USER_HOME but with bad ld interpreter
    # so correct aapt2 ld interpreter is symlinked
    buildPhase = 
      ''
        export GRADLE_USER_HOME=$(mktemp -d)
        export ANDROID_SDK_ROOT=${androidsdk_9_0}/libexec/android-sdk
        export ANDROID_HOME=${androidsdk_9_0}/libexec
        export ANDROID_SDK_HOME=$(mktemp -d)
        # point to local deps repo
        mkdir -p /lib64
        ln -s $(cat $NIX_CC/nix-support/dynamic-linker) /lib64/ld-linux-x86-64.so.2
        gradle --offline --no-daemon --no-build-cache --info --init-script ${gradleInit} ${if release then "assembleRelease" else "assembleDebug"}
      '';

    installPhase =
      ''
        cp Application/build/outputs/apk/debug/*.apk $out
      '';

    passthru = {
      inherit deps;
    };

    meta = with stdenv.lib; {
      description = "Android CardView Sample";
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

