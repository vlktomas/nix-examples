{ nixpkgsSource ? null, localFiles ? true }:

let

  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  serverJobs = import ./server/ci.nix { inherit nixpkgsSource localFiles; };
  clientJobs = import ./client/ci.nix { inherit nixpkgsSource localFiles; };
  answerlibJobs = import ./answerlib/ci.nix { inherit nixpkgsSource localFiles; };
  hellolibJobs = import ./hellolib/ci.nix { inherit nixpkgsSource localFiles; };

  deploymentNodes = import ./cd.nix { inherit nixpkgsSource localFiles; };
  deploymentNodesDistributed = import ./cd.nix {
    inherit nixpkgsSource localFiles; clientLocally = false;
  };

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

    # provide jobs from subprojects
    server = serverJobs;

    client = clientJobs;

    answerlib = answerlibJobs;

    hellolib = hellolibJobs;


    /*
     * Build
     */

    build = [ server.build client.build ];


    /*
     * Test
     */

    nixosVmTest = nixosTest {
      name = "${client.build.pname}-nixos-vm-test";
      nodes = deploymentNodes;
      testScript = ''
        server.start()
        server.wait_for_unit("default.target")
        if not "Hello World!" in server.succeed("${client.build.executable}-wrapped"):
            raise Exception("Bad client output")
      '';
    };

    nixosVmTestDriver = nixosVmTest.driver;

    nixosVmDistributedTest = nixosTest {
      name = "${client.build.pname}-nixos-vm-distributed-test";
      nodes = deploymentNodesDistributed;
      testScript = ''
        server.start()
        client.start()
        server.wait_for_unit("default.target")
        client.wait_for_unit("default.target")
        if not "Hello World!" in client.succeed("${client.build.executable}-wrapped"):
            raise Exception("Bad client output")
      '';
    };

    nixosVmDistributedTestDriver = nixosVmDistributedTest.driver;

    nixosVmContainerTest = nixosTest {
      name = "${client.build.pname}-nixos-vm-container-test";
      machine = { config, ... }: {
        nixpkgs.pkgs = pkgs;
        containers = {
          server = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br0";
            localAddress = "192.168.0.20/24";
            config = { ... }: {
              imports = [ deploymentNodes.server ];
              # Generate /etc/hosts entries for the containers.
              networking.extraHosts = lib.concatStrings (
                lib.mapAttrsToList (
                  name: cfg: lib.optionalString (cfg.localAddress != null)
                  ''
                    ${lib.head (lib.splitString "/" cfg.localAddress)} ${name}
                  ''
                ) config.containers
              );
            };
          };
        };
        networking.useDHCP = false;
        networking.bridges.br0.interfaces = [ ];
        networking.interfaces.br0.ipv4.addresses = [
            { address = "192.168.0.1"; prefixLength = 24; }
        ];
      };
      testScript = ''
        machine.start()
        machine.wait_for_unit("container@server.service")
        if not "Hello World!" in machine.succeed(
            "nixos-container run server -- ${client.build.executable}-wrapped"
        ):
            raise Exception("Bad client output")
      '';
    };

    nixosVmContainerTestDriver = nixosVmContainerTest.driver;

    nixosVmContainerDistributedTest = nixosTest {
      name = "${client.build.pname}-nixos-vm-container-distributed-test";
      machine = { config, ... }: {
        nixpkgs.pkgs = pkgs;
        containers = {
          server = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br0";
            localAddress = "192.168.0.20/24";
            config = { ... }: {
              imports = [ deploymentNodesDistributed.server ];
              # Generate /etc/hosts entries for the containers.
              networking.extraHosts = lib.concatStrings (
                lib.mapAttrsToList (
                  name: cfg: lib.optionalString (cfg.localAddress != null)
                  ''
                    ${lib.head (lib.splitString "/" cfg.localAddress)} ${name}
                  ''
                ) config.containers
              );
            };
          };
          client = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br0";
            localAddress = "192.168.0.21/24";
            config = { ... }: {
              imports = [ deploymentNodesDistributed.client ];
              # Generate /etc/hosts entries for the containers.
              networking.extraHosts = lib.concatStrings (
                lib.mapAttrsToList (
                  name: cfg: lib.optionalString (cfg.localAddress != null)
                  ''
                    ${lib.head (lib.splitString "/" cfg.localAddress)} ${name}
                  ''
                ) config.containers
              );
            };
          };
        };
        networking.useDHCP = false;
        networking.bridges.br0.interfaces = [ ];
        networking.interfaces.br0.ipv4.addresses = [
            { address = "192.168.0.1"; prefixLength = 24; }
        ];
      };
      testScript = ''
        machine.start()
        machine.wait_for_unit("container@server.service")
        machine.wait_for_unit("container@client.service")
        if not "Hello World!" in machine.succeed(
            "nixos-container run client -- ${client.build.executable}-wrapped"
        ):
            raise Exception("Bad client output")
      '';
    };

    nixosVmContainerDistributedTestDriver = nixosVmContainerDistributedTest.driver;

    # TODO testing with NixOps
    deployTest =
      let
        deploymentName = build.pname;
      in
        runCommand "helloanswer-deploy-test"
        {
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
          nixops ssh server -- ${client.build.executable}-wrapped | grep "Hello World!"
          nixops destroy -d ${deploymentName} --confirm
          nixops delete -d ${deploymentName}
        ''
    ;


    /*
     * Release
     */


    /*
     * Pipeline
     */

    # example of combining of multiple pipelines into one
    # first and second pipelines are executed independently and third pipeline
    # is executed only if both of pipelines are successful
    integrationPipeline =
      mkPipeline' (map lib.last [
        hellolib.pipeline answerlib.pipeline
      ]) server.pipeline;

    pipeline = mkPipelineList [
      (
        phase "build" [
          # build server and client or execute server and client pipeline
          server.build
          client.build
          #(server.pipelineJob.overrideAttrs (oldAttrs: { name = "server-pipeline"; }))
          #(client.pipelineJob.overrideAttrs (oldAttrs: { name = "client-pipeline"; }))
        ]
      )
      (
        phase "test" [
          nixosVmTest
          nixosVmDistributedTest
          nixosVmContainerTest
          nixosVmContainerDistributedTest
          #nixopsDeployTest
        ]
      )
      (
        phase "release" [
        ]
      )
      # run server and client pipeline up to release phase
      (
        phase "release-server" [
          (builtins.head (builtins.filter (phase: phase.name == "phase-release") server.pipeline))
        ]
      )
      (
        phase "release-client" [
          (builtins.head (builtins.filter (phase: phase.name == "phase-release") client.pipeline))
        ]
      )
    ];

    pipelineJob = gatherPipelineOutput pipeline;

  }
