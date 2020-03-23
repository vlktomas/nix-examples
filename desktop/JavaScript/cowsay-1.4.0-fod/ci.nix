{ pkgs ? import ./nixpkgs.nix, localFiles ? localFiles }:

with pkgs;

let
  jobs = rec {

    build = import ./default.nix { inherit pkgs localFiles; };

    tarball = releaseTools.sourceTarball {
      buildInputs = [ gettext texinfo ];
      src = build.src;
      name = build.pname;
      version = build.version;
      inherit stdenv autoconf automake libtool;
    };

    # FIXME not working
    nodeTarball = build.tarball;

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
        apps.my-hello.command = "${build}/bin/cowsay";
      };
    };

    dockerImage = dockerTools.buildImage {
      name = "${build.pname}";
      tag = "latest";
      contents = [ build ];
      config = { 
        Cmd = [ "/bin/cowsay" ];
      };
    };

    ociContainer = ociTools.buildContainer {
      args = [
        "${build}/bin/cowsay"
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

