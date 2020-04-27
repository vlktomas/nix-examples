{ nixpkgsSource ? null, localFiles ? true }:

let

  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackageName = nixpkgs.appPackageName;

  mkPipeline = phases: lib.foldl mkDependency null phases;

  mkPipelineList =
    let
      result = phases:
        if phases == [] then
          []
        else
          (result (lib.init phases)) ++ [ (mkPipeline phases) ];
    in
      result;

  mkDependency = prev: next: next.overrideAttrs (oldAttrs: { prev = prev; });

  phase = phaseName: jobs: pkgs.symlinkJoin {
    name = "phase-${phaseName}";
    paths = [ jobs ];
    postBuild = ''
      echo -e "\033[0;32m<<< completed ${phaseName} phase >>>\033[0m"
    '';
  };

  gatherPipelineOutput = pipeline: pkgs.symlinkJoin {
    name = "pipeline";
    paths = pipeline;
  };

in

  with pkgs;

  builtins.trace "Nixpkgs version: ${lib.version}"
  builtins.trace "Use local files: ${lib.boolToString localFiles}"

  rec {


    /*
     * Build
     */

    build = buildDebug;

    buildDebug = pkgs."${appPackageName}".override { release = false; };

    buildRelease = pkgs."${appPackageName}".override { release = true; };


    /*
     * Test
     */

    # TODO testing with AVD emulator
    avdTest = androidenv.emulateApp {
      name = "emulate-myfirstapp";
      platformVersion = "24";
      abiVersion = "x86"; # armeabi-v7a mips, x86, x86_64
      systemImageType = "default";
      #useGoogleAPIs = false;
      enableGPU = true;
      app = build;
      package = "com.example.my.first.app";
      activity = "MainActivity";
    };


    /*
     * Release
     */

    tarball = releaseTools.sourceTarball {
      buildInputs = [ gettext texinfo ];
      src = build.src;
      name = build.pname;
      version = build.version;
      inherit stdenv autoconf automake libtool;
    };


    /*
     * Pipeline
     */

    pipeline = mkPipelineList [
      (
        phase "build" [
          build
        ]
      )
      (
        phase "test" [
          #avdTest
        ]
      )
      (
        phase "release" [
          tarball
        ]
      )
    ];

    pipelineJob = gatherPipelineOutput pipeline;

  }
