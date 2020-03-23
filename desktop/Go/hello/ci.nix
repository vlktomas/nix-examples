{ pkgs ? import ./nixpkgs.nix, localFiles ? true }:

with pkgs;

let
  jobs = rec {

    build = import ./default.nix { inherit pkgs localFiles; };

    # for all available platforms see https://github.com/NixOS/nixpkgs/blob/master/lib/systems/examples.nix
    buildLinux64 = import ./default.nix { pkgs = pkgsCross.gnu64; inherit localFiles; };

    buildLinux32 = import ./default.nix { pkgs = pkgsCross.gnu32; inherit localFiles; };

    buildWindows32 = import ./default.nix { pkgs = pkgsCross.mingwW64; inherit localFiles; };

    buildWindows64 = import ./default.nix { pkgs = pkgsCross.mingw32; inherit localFiles; };

    buildRaspberryPi = import ./default.nix { pkgs = pkgsCross.raspberryPi; inherit localFiles; };

    buildAndroidAarch64 = import ./default.nix { pkgs = pkgsCross.aarch64-android-prebuilt; inherit localFiles; };

    buildAndroidArmv7a = import ./default.nix { pkgs = pkgsCross.armv7a-android-prebuilt; inherit localFiles; };

    buildRiscv64 = import ./default.nix { pkgs = pkgsCross.riscv64; inherit localFiles; };

    buildRiscv32 = import ./default.nix { pkgs = pkgsCross.riscv32; inherit localFiles; };

    buildAarch64 = import ./default.nix { pkgs = pkgsCross.aarch64-multiplatform; inherit localFiles; };

    buildAvr = import ./default.nix { pkgs = pkgsCross.avr; inherit localFiles; };

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
        apps.my-hello.command = "${build}/bin/main";
      };
    };

    dockerImage = dockerTools.buildImage {
      name = "${build.pname}";
      tag = "latest";
      contents = [ build ];
      config = { 
        Cmd = [ "/bin/main" ];
      };
    };

    ociContainer = ociTools.buildContainer {
      args = [
        "${build}/bin/main"
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

    # TODO testing with QEMU, NixOS, NixOps

    # jobs executed in parallel
    release = [ tarball debPackage rpmPackage snapPackage dockerImage ociContainer ];

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

