{ nixpkgsSource ? null, localFiles ? true }:

let

  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackageName = nixpkgs.appPackageName;

  # if dependencies between the phases are not implicit, these can be explicitly created
  mkPipeline = phases: lib.foldl mkDependency null phases;

  # function mkPipeline is sufficient for executing phases in pipeline,
  # but pipeline in form of list is better for further manipulation
  mkPipelineList =
    let
      result = phases:
        if phases == [] then
          []
        else
          (result (lib.init phases)) ++ [ (mkPipeline phases) ];
    in
      result;

  # helper function to create ad-hoc dependency between two derivations
  mkDependency = prev: next: next.overrideAttrs (oldAttrs: { prev = prev; });

  # phase as derivation, which symlinks all jobs outputs into single directory
  phase = phaseName: jobs: pkgs.symlinkJoin {
    name = "${phaseName}-phase";
    paths = [ jobs ];
    postBuild = ''
      echo -e "\033[0;32m<<< completed ${phaseName} phase >>>\033[0m"
    '';
  };

  # symlink all phases outputs into single directory
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

    # for all available platforms see
    # https://github.com/NixOS/nixpkgs/blob/master/lib/systems/examples.nix

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

    scriptTest = runCommand "${build.pname}-test"
      {
        # test-only dependencies
        nativeBuildInputs = [ build ];
      }
      ''
        mkdir -p $out/tests/${build.pname}-test
        echo "Hello, world!" > expected
        ${build.executable} > given
        diff expected given > $out/tests/${build.pname}-test/result
      ''
    ;

    nixosVmTest = nixosTest {
      machine = { ... }: {
        imports = [ ./module.nix ];
      };
      testScript = ''
        machine.start()
        machine.wait_for_unit("default.target")
        machine.succeed("${build.executable}")
      '';
    };

    # run test interactively
    nixosVmTestDriver = nixosVmTest.driver;

    nixosVmContainerTest = nixosTest {
      machine = { ... }: {
        containers."${build.pname}" = {
          autoStart = true;
          config = { ... }: {
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

    # run test interactively
    nixosVmContainerTestDriver = nixosVmContainerTest.driver;

    # TODO testing with NixOps
    deployTest =
      let
        deploymentName = build.pname;
      in
        runCommand "${build.pname}-deploy-test"
        {
          # test-only dependencies
          buildInputs = [ nixops cacert nix ];
          src = build.src;
          NIX_PATH = "nixpkgs=${nixpkgs}";
        }
        ''
          mkdir -p $out
          cp -pr --reflink=auto -- "$src"/* .
          nixops create ./cd-vbox.nix -d ${deploymentName}
          nixops set-args --arg nixpkgsSource ${nixpkgs} -d ${deploymentName}
          nixops set-args --arg localFiles true -d ${deploymentName}
          nixops info -d ${deploymentName}
          nixops deploy -d ${deploymentName} --force-reboot
          echo "Hello, world!" > expected
          nixops ssh server -- ${build.executable} > given
          diff expected given > $out/result
          nixops destroy -d ${deploymentName}
          nixops delete -d ${deploymentName}
        ''
    ;


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

    dockerImageFromAnotherImage = dockerTools.buildImage {
      name = "${build.pname}";
      tag = "latest";
      fromImage = dockerTools.buildImage {
        name = "bash";
        tag = "latest";
        contents = [ bashInteractive ];
      };
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

    # for all available NixOS images see nix-community/nixos-generators
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

    # phases in pipeline are executed sequentially
    # jobs in phase can be executed in parallel
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
          nixopsDeployTest
        ]
      )
      (
        phase "release" [
          tarball
          debPackage
          rpmPackage
          snapPackage
          dockerImage
          ociContainer
          nixosIso
        ]
      )
    ];

    pipelineJob = gatherPipelineOutput pipeline;

  }

