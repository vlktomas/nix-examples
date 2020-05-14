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

    build = pkgs."${appPackageName}";


    /*
     * Test
     */
    scriptTest = runCommand "${build.pname}-test"
      { nativeBuildInputs = [ build ]; }
      ''
        mkdir -p $out/tests/${build.pname}-test
        echo "Bad arguments. Please specify server address and port." > expected
        ${build.executable} > given || true
        diff expected given > $out/tests/${build.pname}-test/result
      ''
    ;


    /*
     * Release
     */

    snapPackage = snapTools.makeSnap {
      meta = {
        name = build.pname;
        summary = build.meta.description;
        description = build.meta.longDescription;
        architectures = [ "amd64" ];
        confinement = "strict";
        apps.example.command = "${build}/bin/${build.executable}";
      };
    };

    dockerImage = dockerTools.buildImage {
      name = "${build.pname}";
      tag = "latest";
      contents = [ build ];
      config = {
        Cmd = [ "/bin/${build.executable}" ];
      };
    };

    ociContainer = ociTools.buildContainer {
      args = [
        "${build}/bin/${build.executable}"
      ];
    };

    nixosIso = (
      nixos (
          { config, modulesPath, ... }: {
            imports = [
              "${toString modulesPath}/installer/cd-dvd/iso-image.nix"
              ./module.nix
            ];
            isoImage.makeEfiBootable = true;
            isoImage.makeUsbBootable = true;
            users.users.root.password = "nixos";
          }
        )
      ).config.system.build.isoImage;

    nixosVm = (
      nixos (
          { config, modulesPath, ... }: {
            imports = [
              "${toString modulesPath}/virtualisation/qemu-vm.nix"
              ./module.nix
            ];
            users.users.root.password = "nixos";
          }
        )
      ).config.system.build.vm;


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
          scriptTest
        ]
      )
      (
        phase "release" [
          snapPackage
          dockerImage
          ociContainer
          nixosIso
        ]
      )
    ];

    pipelineJob = gatherPipelineOutput pipeline;

  }
