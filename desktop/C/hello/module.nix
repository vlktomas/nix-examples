{ config, lib, pkgs, ... }:

with lib;

let

  pkg = import ./default.nix { inherit pkgs; };

in

  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }

