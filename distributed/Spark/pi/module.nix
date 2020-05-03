{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.pi;
  pkg = pkgs.pi;
in
  {

    # interface

    options.services.pi = with types; {

      enable = mkEnableOption "Spark Pi example";

      submit = mkOption {
        type = bool;
        default = true;
        description = "Whether the app should be submitted immediately after start";
      };

      master = mkOption {
        type = bool;
        default = false;
        description = "Whether it is a master node";
      };

      worker = mkOption {
        type = bool;
        default = false;
        description = "Whether it is a worker node";
      };

      masterHost = mkOption {
        type = str;
        default = "127.0.0.1";
        description = "Master host address.";
      };

      masterIp = mkOption {
        type = str;
        default = "127.0.0.1";
        description = "Master local IP address.";
      };

      masterPort = mkOption {
        type = port;
        default = 7077;
        description = "Master port.";
      };

      masterWebUIPort = mkOption {
        type = port;
        default = 8080;
        description = "Master web UI port.";
      };

      workerIp = mkOption {
        type = str;
        default = "127.0.0.1";
        description = "Worker local IP address.";
      };

      workerPort = mkOption {
        type = port;
        default = 7078;
        description = "Worker port.";
      };

      workerWebUIPort = mkOption {
        type = port;
        default = 8081;
        description = "Worker web UI port.";
      };

      driverPort = mkOption {
        type = port;
        default = 7080;
        description = "Driver port.";
      };

      UIPort = mkOption {
        type = port;
        default = 4040;
        description = "Application UI port.";
      };

      blockManagerPort = mkOption {
        type = port;
        default = 7090;
        description = "Block manager port.";
      };

      masterArgs = mkOption {
        type = str;
        default = "";
        description = "Additional arguments supplied to start-master.sh.";
        example = "--webui-port 9090";
      };

      workerArgs = mkOption {
        type = str;
        default = "";
        description = "Additional arguments supplied to start-slave.sh.";
        example = "--memory 512M";
      };

      submitArgs = mkOption {
        type = str;
        default = "";
        description = "Additional arguments supplied to spart-submit.sh.";
        example = "--memory 512M";
      };

      workersCount = mkOption {
        type = ints.unsigned;
        default = 1;
        description = "Number of workers, which must be connected to master, to start application.";
      };

      partitions = mkOption {
        type = ints.unsigned;
        default = 2;
        description = "Number of partitions.";
      };
    };

    # implementation

    config = mkIf cfg.enable {

      assertions = [
        {
          assertion = !(cfg.master == cfg.worker);
          message = "Please select one and only one from the either option master or worker";
        }
      ];

      networking.firewall.allowedTCPPorts =
        (optionals cfg.master [ cfg.masterPort cfg.masterWebUIPort cfg.driverPort cfg.UIPort cfg.blockManagerPort ]) ++
        (optionals cfg.worker [ cfg.workerPort cfg.workerWebUIPort ]);

      environment.systemPackages = [ pkgs.spark ];

      users.groups.spark = {};
      users.users.spark = {
        group = "spark";
        createHome = true;
        home = "/home/spark";
      };

      systemd.services.spark-worker = mkIf cfg.worker {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.spark pkgs.curl ];
        environment = {
          SPARK_MASTER_HOST = cfg.masterHost;
          SPARK_LOCAL_IP = cfg.workerIp;
          SPARK_LOG_DIR = "${config.users.users.spark.home}/logs";
          SPARK_WORKER_DIR = "${config.users.users.spark.home}/work";
          SPARK_NO_DAEMONIZE = "true";
          SPARK_MASTER_PORT = toString cfg.masterPort;
          SPARK_MASTER_WEBUI_PORT = toString cfg.masterWebUIPort;
          SPARK_WORKER_PORT = toString cfg.workerPort;
          SPARK_WORKER_WEBUI_PORT = toString cfg.workerWebUIPort;
        };
        script = ''
          set +e
          max_retry=120
          counter=0
          until curl http://${cfg.masterHost}:${toString cfg.masterWebUIPort} &> /dev/null
          do
             [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
             echo "Waiting for master"
             ((counter++))
             sleep 1s
          done
          ${pkgs.spark}/lib/spark-2.4.4-bin-without-hadoop/sbin/start-slave.sh \
            spark://${cfg.masterHost}:${toString cfg.masterPort} ${cfg.workerArgs}
        '';
        serviceConfig.User = "spark";
      };

      systemd.services.spark-master = mkIf cfg.master {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          SPARK_MASTER_HOST = cfg.masterIp;
          SPARK_LOCAL_IP = cfg.masterIp;
          SPARK_LOG_DIR = "${config.users.users.spark.home}/logs";
          SPARK_NO_DAEMONIZE = "true";
          SPARK_MASTER_PORT = toString cfg.masterPort;
          SPARK_MASTER_WEBUI_PORT = toString cfg.masterWebUIPort;
          SPARK_WORKER_PORT = toString cfg.workerPort;
          SPARK_WORKER_WEBUI_PORT = toString cfg.workerWebUIPort;
        };
        path = [ pkgs.spark ];
        script = ''
          ${pkgs.spark}/lib/spark-2.4.4-bin-without-hadoop/sbin/start-master.sh ${cfg.masterArgs}
        '';
        serviceConfig.User = "spark";
      };

      systemd.services.pi = mkIf cfg.master {
        description = "Spark Pi";
        wantedBy = optional cfg.submit "multi-user.target";
        after = [ "spark-master" ];
        wants = [ "spark-master" ];
        path = [ pkgs.spark pkgs.curl pkg ];
        environment = {
          SPARK_MASTER_HOST = cfg.masterIp;
          SPARK_LOCAL_IP = cfg.masterIp;
          SPARK_MASTER_PORT = toString cfg.masterPort;
          SPARK_MASTER_WEBUI_PORT = toString cfg.masterWebUIPort;
          SPARK_WORKER_PORT = toString cfg.workerPort;
          SPARK_WORKER_WEBUI_PORT = toString cfg.workerWebUIPort;
        };
        script = ''
          set +e
          max_retry=120
          counter=0
          until curl http://${cfg.masterIp}:${toString cfg.masterWebUIPort} &> /dev/null
          do
             [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
             echo "Waiting for master"
             ((counter++))
             sleep 1s
          done
          max_retry=120
          counter=0
          until curl http://${cfg.masterIp}:${toString cfg.masterWebUIPort} -s | grep "Workers (${toString cfg.workersCount})"
          do
             [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
             echo "Waiting for workers"
             ((counter++))
             sleep 1s
          done
          ${pkgs.spark}/bin/spark-submit \
            --class org.apache.spark.examples.JavaSparkPi \
            --conf "spark.driver.port=${toString cfg.driverPort}" \
            --conf "spark.driver.host=${toString cfg.masterIp}" \
            --conf "spark.ui.port=${toString cfg.UIPort}" \
            --conf "spark.blockManager.port=${toString cfg.blockManagerPort}" \
            --master spark://${cfg.masterIp}:${toString cfg.masterPort} ${cfg.submitArgs} --verbose \
            ${pkg}/share/java/pi-1.0.jar ${toString cfg.partitions}
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "spark";
          RemainAfterExit = true;
        };
      };

    };
  }
