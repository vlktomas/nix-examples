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

    build = pkgs."${appPackageName}";


    /*
     * Test
     */

    scriptTest = runCommand "${build.pname}-test"
      { nativeBuildInputs = [ build ]; }
      ''
        mkdir -p $out/tests/${build.pname}-test
        ${build.executable} | grep ":: Spring Boot ::"
      ''
    ;

    nixosVmTest = nixosTest {
      name = "${build.pname}-nixos-vm-test";
      machine = { ... }: {
        nixpkgs.pkgs = pkgs;
        imports = [ ./module.nix ];
      };
      testScript = ''
        machine.start()
        machine.wait_for_unit("default.target")
        machine.succeed("${build.executable}")
      '';
    };

    nixosVmTestDriver = nixosVmTest.driver;

    nixosVmContainerTest = nixosTest {
      name = "${build.pname}-nixos-vm-container-test";
      machine = { ... }: {
        nixpkgs.pkgs = pkgs;
        containers."${build.pname}" = {
          autoStart = true;
          config = { ... }: {
            nixpkgs.pkgs = pkgs;
            imports = [ ./module.nix ];
          };
        };
      };
      testScript = ''
        machine.start()
        machine.wait_for_unit("container@${build.pname}.service")
        machine.succeed("nixos-container run ${build.pname} -- ${build.executable}")
      '';
    };

    nixosVmContainerTestDriver = nixosVmContainerTest.driver;


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
        apps."${build.pname}".command = "${build}/bin/${build.executable}";
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
          nixosVmTest
          nixosVmContainerTest
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
