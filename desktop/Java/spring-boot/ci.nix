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

    build = pkgs."${appPackageName}";

    buildLinux64 = pkgsCross.gnu64."${appPackageName}";

    buildLinux32 = pkgsCross.gnu32."${appPackageName}";

    buildWindows32 = pkgsCross.mingwW64."${appPackageName}";

    buildWindows64 = pkgsCross.mingw32."${appPackageName}";

    buildRaspberryPi = pkgsCross.raspberryPi."${appPackageName}";

    buildAndroidAarch64 = pkgsCross.aarch64-android-prebuilt."${appPackageName}";

    buildAndroidArmv7a = pkgsCross.armv7a-android-prebuilt."${appPackageName}";

    buildRiscv64 = pkgsCross.riscv64."${appPackageName}";

    buildRiscv32 = pkgsCross.riscv32."${appPackageName}";

    buildAarch64 = pkgsCross.aarch64-multiplatform."${appPackageName}";

    buildAvr = pkgsCross.avr."${appPackageName}";


    /*
     * Test
     */

    # TODO
    scriptTest = runCommand "${build.pname}-test"
      { nativeBuildInputs = [ build ]; }
      ''
        mkdir -p $out/tests/${build.pname}-test
        ${build.executable} | grep ":: Spring Boot ::"
      ''
    ;

    nixosVmTest = nixosTest {
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

    tarball = releaseTools.sourceTarball {
      buildInputs = [ gettext texinfo ];
      src = build.src;
      name = build.pname;
      version = build.version;
      inherit stdenv autoconf automake libtool;
    };

    debPackage = releaseTools.debBuild {
      diskImage = vmTools.diskImageFuns.debian8x86_64 {};
      src = build.src;
      name = "${build.pname}-${build.version}-deb";
    };

    rpmPackage = releaseTools.rpmBuild {
      diskImage = vmTools.diskImageFuns.fedora27x86_64 {};
      src = build.src;
      name = "${build.pname}-${build.version}-rpm";
    };

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
          #tarball
          #debPackage
          #rpmPackage
          #snapPackage
          #dockerImage
          #ociContainer
          #nixosIso
        ]
      )
    ];

    pipelineJob = gatherPipelineOutput pipeline;

  }
