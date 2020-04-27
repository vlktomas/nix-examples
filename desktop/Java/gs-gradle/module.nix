{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.gs-gradle;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
