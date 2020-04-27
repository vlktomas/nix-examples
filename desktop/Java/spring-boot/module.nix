{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.spring-boot;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
