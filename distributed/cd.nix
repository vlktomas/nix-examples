# TODO work in progress
{ nrMachines }:

with import <nixpkgs/pkgs/lib>;

let

  makeMachine = n: nameValuePair "webserver-${toString n}"
    ({ config, pkgs, ... }:
    { deployment.targetEnv = "virtualbox";
      services.httpd.enable = true;
      services.httpd.adminAddr = "foo@example.org";
    });

in listToAttrs (map makeMachine (range 1 nrMachines))

# $ nixops create deploy.nix
# $ nixops set-args --arg nrMachines 10
# $ nixops deploy
# $ nixops set-args --arg nrMachines 20
# $ nixops deploy
