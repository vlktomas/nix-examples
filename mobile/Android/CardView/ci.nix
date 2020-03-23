{ pkgs ? import ./nixpkgs.nix, localFiles ? true }:

with pkgs;

let
  jobs = rec {

    build = buildDebug;

    buildDebug = import ./default.nix { inherit pkgs localFiles; release = false; };

    buildRelease = import ./default.nix { inherit pkgs localFiles; release = true; };

    tarball = releaseTools.sourceTarball {
      buildInputs = [ gettext texinfo ];
      src = app.src;
      name = app.pname;
      version = app.version;
      inherit stdenv autoconf automake libtool;
    };

    # TODO test with bash script
    tests = pkgs.runCommand "${build.pname}-tests" 
      {
        # tests-only dependencies
        nativeBuildInputs = [ build ];
      }
      ''
        mkdir -p $out
        echo "Hello world" > expected
        example > given
        diff expected given > $out/result
      ''
    ;

    # TODO testing with AVD emulator
    emulate = androidenv.emulateApp {
      name = "emulate-CardView";
      platformVersion = "24";
      abiVersion = "x86"; # armeabi-v7a mips, x86, x86_64
      systemImageType = "default";
      #useGoogleAPIs = false;
      app = build;
      package = "com.example.android.cardview";
      activity = "CardViewActivity";
    };

    # jobs executed in parallel
    release = [ tarball ];

    # jobs executed sequentially
    pipeline = mkPipelineList [ build tests release ];

    # if dependencies between the phases are not implicit, these can be explicitly created
    mkPipeline = phases: pkgs.lib.foldl mkDependency null phases;

    # function mkPipeline is sufficient for executing phases in pipeline,
    # but pipeline in form of list is better for further manipulation
    mkPipelineList =
      let
        result = phases:
          if phases == [] then
            []
          else
            (result (pkgs.lib.init phases)) ++ [ (mkPipeline phases) ];
      in
        result;

    # helper function to create ad-hoc dependency between two derivations
    mkDependency = prev: next: next.overrideAttrs (oldAttrs: { prev = prev; });

  };
in
  jobs

