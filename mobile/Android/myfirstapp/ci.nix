{ nixpkgsSource ? null, localFiles ? true }:

let

  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackageName = nixpkgs.appPackageName;

  mkPipeline = mkPipeline' null;
  mkPipeline' = prev: phases: lib.foldl mkDependency prev phases;

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

  phase = name: jobs:
    let
      # backport (linkFarmFromDrvs isn't in Nixpkgs 20.03)
      linkFarmFromDrvs =
        let mkEntryFromDrv = drv: { name = drv.name; path = drv; };
        in pkgs.linkFarm name (map mkEntryFromDrv jobs);
    in
      pkgs.runCommand "phase-${name}" {} ''
        mkdir -p $out
        cd $out
        ln -s ${linkFarmFromDrvs} ${name}
      '';

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
        ]
      )
    ];

    pipelineJob = gatherPipelineOutput pipeline;

  }
