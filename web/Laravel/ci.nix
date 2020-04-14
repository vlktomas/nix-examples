{ pkgs ? (import ./nixpkgs.nix).pkgs, nixos ? (import ./nixpkgs.nix).nixos, localFiles ? true }:

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

    dockerImage = dockerTools.buildImage {
      name = "${build.pname}";
      tag = "latest";
      contents = [ build ];
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
    release = [ tarball dockerImage ];

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

