{
  network.description = "Laravel";

  webserver = {

    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.memorySize = 1024; # megabytes
    deployment.virtualbox.vcpu = 2; # number of cpus
  };

  /*
  databaseserver = {
    deployment.targetEnv = "virtualbox";
  };
  */

  /*
  fileserver = {
    deployment.targetEnv = "virtualbox";
  };
  */
}
