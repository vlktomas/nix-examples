{ pkgs ? (import ./nixpkgs.nix).pkgs, nixos ? (import ./nixpkgs.nix).nixos, localFiles ? true }:

with pkgs;

let
  jobs = rec {

    build = import ./default.nix { inherit pkgs localFiles; };

    # for all available platforms see https://github.com/NixOS/nixpkgs/blob/master/lib/systems/examples.nix
    buildLinux64 = import ./default.nix { pkgs = pkgsCross.gnu64; inherit fetchSources; };

    buildLinux32 = import ./default.nix { pkgs = pkgsCross.gnu32; inherit fetchSources; };

    buildWindows32 = import ./default.nix { pkgs = pkgsCross.mingwW64; inherit fetchSources; };

    buildWindows64 = import ./default.nix { pkgs = pkgsCross.mingw32; inherit fetchSources; };

    buildRaspberryPi = import ./default.nix { pkgs = pkgsCross.raspberryPi; inherit fetchSources; };

    buildAndroidAarch64 = import ./default.nix { pkgs = pkgsCross.aarch64-android-prebuilt; inherit fetchSources; };

    buildAndroidArmv7a = import ./default.nix { pkgs = pkgsCross.armv7a-android-prebuilt; inherit fetchSources; };

    buildRiscv64 = import ./default.nix { pkgs = pkgsCross.riscv64; inherit fetchSources; };

    buildRiscv32 = import ./default.nix { pkgs = pkgsCross.riscv32; inherit fetchSources; };

    buildAarch64 = import ./default.nix { pkgs = pkgsCross.aarch64-multiplatform; inherit fetchSources; };

    buildAvr = import ./default.nix { pkgs = pkgsCross.avr; inherit fetchSources; };

    tarball = releaseTools.sourceTarball {
      buildInputs = [ gettext texinfo ];
      src = build.src;
      name = build.pname;
      version = build.version;
      inherit stdenv autoconf automake libtool;
    };

    debPackage = releaseTools.debBuild {
      diskImage = vmTools.diskImageFuns.debian8x86_64 {};
      src       = build.src;
      name      = "${build.pname}-${build.version}-deb";
    };

    rpmPackage = releaseTools.rpmBuild {
      diskImage = vmTools.diskImageFuns.fedora27x86_64 {};
      src       = build.src;
      name      = "${build.pname}-${build.version}-rpm";
    };

    snapPackage = snapTools.makeSnap {
      meta = {
        name = build.pname;
        summary = build.meta.description;
        description = build.meta.longDescription;
        architectures = [ "amd64" ];
        confinement = "strict";
        apps.my-hello.command = "${build}/bin/example";
      };
    };

    dockerImage = dockerTools.buildImage {
      name = "${build.pname}";
      tag = "latest";
      contents = [ build ];
      config = { 
        Cmd = [ "/bin/example" ];
      };
    };

    dockerImageFromAnotherImage = dockerTools.buildImage {
      name = "${build.pname}";
      tag = "latest";
      fromImage = dockerTools.buildImage {
        name = "bash";
        tag = "latest";
        contents = [ pkgs.bashInteractive ];
      };
      contents = [ build ];
      config = { 
        Cmd = [ "/bin/example" ];
      };
    };

    ociContainer = ociTools.buildContainer {
      args = [
        "${build}/bin/example"
      ];
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

    # TODO testing with QEMU/KVM, NixOS, NixOps

    # TODO testing with NixOps
    deploy = pkgs.runCommand "${build.pname}-deploy" 
      {
        # deploy-only dependencies
        nativeBuildInputs = [ build pkgs.nixops ];
      }
      ''
        nixops create ${./cd.nix} ${./cd-vbox.nix} -d ${build.pname}
        nixops deploy -d ${build.pname}
      ''
    ;

    # jobs executed in parallel
    release = [ tarball debPackage rpmPackage snapPackage dockerImage ociContainer ];

    # TODO deploy with NixOps
    deploy = pkgs.runCommand "${build.pname}-deploy" 
      {
        # deploy-only dependencies
        nativeBuildInputs = [ build pkgs.nixops ];
      }
      ''
        nixops create ${./cd.nix} ${./cd-nixos.nix} -d ${build.pname}
        nixops deploy -d ${build.pname}
      ''
    ;

    # jobs executed sequentially
    pipeline = mkPipelineList [ build tests release deploy ];

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

