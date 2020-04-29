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
      { nativeBuildInputs = [ build python37Packages.pdftotext ]; }
      ''
        mkdir -p $out/tests/${build.pname}-test
        echo "Hello, world!" > expected
        ${build.executable} > test.pdf
        pdftotext test.pdf test.txt
        grep "hello world" test.txt
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
