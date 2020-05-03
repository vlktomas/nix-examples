{ nixpkgsSource ? null, localFiles ? true }:

let

  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackageName = nixpkgs.appPackageName;

  deploymentNodes = { workersCount }: import ./cd.nix { inherit nixpkgsSource localFiles workersCount; };

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
      { nativeBuildInputs = [ spark build ]; }
      ''
        mkdir -p $out/tests/${build.pname}-test
        ${pkgs.spark}/bin/spark-submit \
          --class org.apache.spark.examples.JavaSparkPi \
          --master local \
          ${build}/share/java/pi-1.0.jar 10 | grep "Pi is roughly 3.1"
      ''
    ;

    nixosVmTest = nixosTest {
      nodes =
        lib.mapAttrs (
          name: node:
            { ... }: {
              imports = [ node ];
              services.pi.masterIp = (
                if name == "master" then
                  "192.168.1.1"
                else
                  null
              );
              services.pi.workerIp = (
                if name == "master" then
                  null
                else
                  "192.168.1.${with lib; toString ((toInt (removePrefix "worker" name)) + 1)}"
              );
              services.pi.workerArgs = (
                if lib.hasPrefix "worker" name then
                  "--memory 768M"
                else
                  ""
              );
              services.pi.submitArgs = (
                if name == "master" then
                  "--executor-memory 512M --driver-memory 512M"
                else
                  ""
              );
              virtualisation.memorySize = 1536;
            }
        ) (deploymentNodes { workersCount = 2; });
      testScript = ''
        start_all()
        master.wait_for_unit("pi.service")
        if not "Pi is roughly 3.1" in master.execute("systemctl status pi --no-pager -l")[1]:
            raise Exception("Bad pi output")
      '';
    };

    nixosVmTestDriver = nixosVmTest.driver;

    nixosVmContainerTest = nixosTest {
      machine = { config, ... }: {
        nixpkgs.pkgs = pkgs;
        containers =
          lib.mapAttrs (
            name: node: {
              timeoutStartSec = "3min";
              autoStart = true;
              privateNetwork = true;
              hostBridge = "br0";
              localAddress = (
                if name == "master" then
                  "192.168.0.10/24"
                else
                  "192.168.0.${with lib; toString ((toInt (removePrefix "worker" name)) + 20)}/24"
              );
              config = { ... }: {
                imports = [ node ];
                services.pi.masterIp = (
                  if name == "master" then
                    "192.168.0.10"
                  else
                    null
                );
                services.pi.workerIp = (
                  if name == "master" then
                    null
                  else
                    "192.168.0.${with lib; toString ((toInt (removePrefix "worker" name)) + 20)}"
                );
                services.pi.workerArgs = (
                  if lib.hasPrefix "worker" name then
                    "--memory 768M"
                  else
                    ""
                );
                services.pi.submitArgs = (
                  if name == "master" then
                    "--executor-memory 512M --driver-memory 512M"
                  else
                    ""
                );
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
            }
          ) (deploymentNodes { workersCount = 2; });
        networking.useDHCP = false;
        networking.bridges.br0.interfaces = [ ];
        networking.interfaces.br0.ipv4.addresses = [
            { address = "192.168.0.1"; prefixLength = 24; }
        ];
        virtualisation.memorySize = 2048;
      };
      testScript = ''
        machine.start()
        machine.wait_for_unit("container@master.service")
        if (
            not "Pi is roughly 3.1"
            in machine.execute(
                "nixos-container run master -- systemctl status pi --no-pager -l"
            )[1]
        ):
            raise Exception("Bad pi output")
      '';
    };

    nixosVmContainerTestDriver = nixosVmContainerTest.driver;

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
          nixops set-args --arg workersCount 2 -d ${deploymentName}
          nixops info -d ${deploymentName}
          nixops deploy -d ${deploymentName} --force-reboot
          sleep 30s
          nixops ssh master -- systemctl status pi --no-pager -l | grep "Pi is roughly 3.1"
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
        ]
      )
    ];

    pipelineJob = gatherPipelineOutput pipeline;

  }
