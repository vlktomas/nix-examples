{ nixpkgsSource ? null, localFiles ? true }:

let

  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackageName = nixpkgs.appPackageName;

  deploymentNodes = import ./cd.nix { inherit nixpkgsSource localFiles; };
  deploymentNodesDistributed = import ./cd.nix {
    inherit nixpkgsSource localFiles; databaseLocally = false; storageLocally = false;
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


    /*
     * Build
     */

    build = pkgs."${appPackageName}";


    /*
     * Test
     */

    nixosVmTest = nixosTest {
      name = "${build.pname}-nixos-vm-test";
      nodes = deploymentNodes // {
        client = { pkgs, ... }: {
          environment.systemPackages = with pkgs; [ curl ];
        };
      };
      testScript = ''
        webserver.start()
        webserver.wait_for_unit("default.target")
        client.start()
        client.wait_for_unit("default.target")
        if not "<title>Laravel</title>" in client.succeed(
            "curl --insecure 'https://webserver'"
        ):
            raise Exception("Not Laravel default welcome page")
      '';
    };

    nixosVmTestDriver = nixosVmTest.driver;

    nixosVmDistributedTest = nixosTest {
      name = "${build.pname}-nixos-vm-distributed-test";
      nodes = deploymentNodesDistributed // {
        client = { pkgs, ... }: {
          environment.systemPackages = with pkgs; [ curl ];
        };
      };
      testScript = ''
        fileserver.start()
        fileserver.wait_for_unit("default.target")
        dbserver.start()
        dbserver.wait_for_unit("default.target")
        webserver.start()
        webserver.wait_for_unit("default.target")
        client.start()
        client.wait_for_unit("default.target")
        if not "<title>Laravel</title>" in client.succeed(
            "curl --insecure 'https://webserver'"
        ):
            raise Exception("Not Laravel default welcome page")
      '';
    };

    nixosVmDistributedTestDriver = nixosVmDistributedTest.driver;

    nixosVmContainerTest = nixosTest {
      name = "${build.pname}-nixos-vm-container-test";
      machine = { config, ... }: {
        nixpkgs.pkgs = pkgs;
        containers = {
          webserver = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br0";
            localAddress = "192.168.0.20/24";
            config = { ... }: {
              imports = [ deploymentNodes.webserver ];
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
            config = { pkgs, ... }: {
              # Generate /etc/hosts entries for the containers.
              networking.extraHosts = lib.concatStrings (
                lib.mapAttrsToList (
                  name: cfg: lib.optionalString (cfg.localAddress != null)
                  ''
                    ${lib.head (lib.splitString "/" cfg.localAddress)} ${name}
                  ''
                ) config.containers
              );
              environment.systemPackages = with pkgs; [ curl ];
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
        machine.wait_for_unit("container@webserver.service")
        machine.wait_for_unit("container@client.service")
        if not "<title>Laravel</title>" in machine.succeed(
            "nixos-container run client -- curl --insecure 'https://webserver'"
        ):
            raise Exception("Not Laravel default welcome page")
      '';
    };

    nixosVmContainerTestDriver = nixosVmContainerTest.driver;

    nixosVmContainerDistributedTest = nixosTest {
      name = "${build.pname}-nixos-vm-container-distributed-test";
      machine = { config, ... }: {
        containers = {
          fileserver = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br0";
            localAddress = "192.168.0.20/24";
            config = { ... }: {
              imports = [ deploymentNodesDistributed.fileserver ];
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
          dbserver = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br0";
            localAddress = "192.168.0.21/24";
            config = { ... }: {
              imports = [ deploymentNodesDistributed.dbserver ];
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
          webserver = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br0";
            localAddress = "192.168.0.22/24";
            config = { ... }: {
              imports = [ deploymentNodesDistributed.webserver ];
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
            localAddress = "192.168.0.23/24";
            config = { pkgs, ... }: {
              # Generate /etc/hosts entries for the containers.
              networking.extraHosts = lib.concatStrings (
                lib.mapAttrsToList (
                  name: cfg: lib.optionalString (cfg.localAddress != null)
                  ''
                    ${lib.head (lib.splitString "/" cfg.localAddress)} ${name}
                  ''
                ) config.containers
              );
              environment.systemPackages = with pkgs; [ curl ];
            };
          };
        };
        networking.useDHCP = false;
        networking.bridges.br0.interfaces = [ ];
        networking.interfaces.br0.ipv4.addresses = [
            { address = "192.168.0.1"; prefixLength = 24; }
        ];

        systemd.services."container@webserver" = {
          after = [ "container@fileserver.service" "container@dbserver.service" ];
          wants = [ "container@fileserver.service" "container@dbserver.service" ];
        };
      };
      testScript = ''
        machine.start()
        machine.wait_for_unit("container@webserver.service")
        machine.wait_for_unit("container@client.service")
        if not "<title>Laravel</title>" in machine.succeed(
            "nixos-container run client -- curl --insecure 'https://webserver'"
        ):
            raise Exception("Not Laravel default welcome page")
      '';
    };

    nixosVmContainerDistributedTestDriver = nixosVmContainerDistributedTest.driver;

    # TODO testing with NixOps
    deployTest =
      let
        deploymentName = build.pname;
      in
        runCommand "${build.pname}-deploy-test"
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
          # get webserver IP address
          WEBSERVER_IP=$(nixops info --deployment laravel-vbox --no-eval --plain | awk '{print $1 " " $(NF)}' | grep webserver | awk '{print $(NF)}')
          curl https://${WEBSERVER_IP}
          nixops destroy -d ${deploymentName} --confirm
          nixops delete -d ${deploymentName}
        ''
    ;


    /*
     * Release
     */

    dockerImage = dockerTools.buildImage {
      name = "${build.pname}";
      tag = "latest";
      contents = [ build ];
    };


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
          nixosVmTest
          nixosVmDistributedTest
          nixosVmContainerTest
          nixosVmContainerDistributedTest
          #nixopsDeployTest
        ]
      )
      (
        phase "release" [
          dockerImage
        ]
      )
    ];

    pipelineJob = gatherPipelineOutput pipeline;

  }
