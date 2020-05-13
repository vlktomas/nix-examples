{
  # dependencies
  stdenv, fetchurl, nix-gitignore, androidsdk_9_0, gradle, perl, zip, unzip, writeText, makeWrapper,

  # args
  localFiles ? false,
  release ? true
}:

let

  pname = "cardview";
  version = "0.1.0";

  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    nativeBuildInputs = [ gradle perl zip unzip ];

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

    buildPhase = ''
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
    installPhase = ''
      find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\|aar\)' \
        | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
        | sh
    '';

    # On Linux, we need to patch the interpreter in Java packages that contain native executables to use Nix's interpreter instead
    # see https://github.com/status-im/status-react/pull/8549/
    fixupPhase = ''
      prevSet=$-
      set -e

      # Patch executables from maven dependency to use Nix's interpreter
      tmpDir=$(mktemp -d)
      # patchelf aapt2
      depPath=$(find $out -regex '.*aapt2.*linux\.jar')
      echo $depPath
      unzip $depPath -d $tmpDir
      for exe in `find $tmpDir/ -type f -executable`; do
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $exe
        # set the same timestamp as NOTICE file
        touch --reference $tmpDir/NOTICE $exe
        ls -al $tmpDir
      done

      # Rebuild the .jar file with patched binaries
      pushd $tmpDir > /dev/null
      rm $depPath
      zip $depPath -rX *
      popd > /dev/null
      rm -rf $tmpDir

      set $prevSet
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "0x6l2wnpw4s1kalfassqh4z1lcqqbz50dpk2x1wlgd0zfdwznlij";
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

    buildPhase = ''
      export GRADLE_USER_HOME=$(mktemp -d)
      export ANDROID_SDK_ROOT=${androidsdk_9_0}/libexec/android-sdk
      export ANDROID_HOME=${androidsdk_9_0}/libexec
      export ANDROID_SDK_HOME=$(mktemp -d)
      export PATH="$ANDROID_SDK_ROOT/bin:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/28.0.3:$PATH"
      # point to local deps repo
      gradle --offline --no-daemon --no-build-cache --info --init-script ${gradleInit} ${if release then "assembleRelease" else "assembleDebug"}
    '';

    installPhase = ''
      cp Application/build/outputs/apk/debug/*.apk $out
    '';

    passthru = {
      inherit deps gradleInit;
    };

    meta = with stdenv.lib; {
      description = "Android CardView Sample";
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

