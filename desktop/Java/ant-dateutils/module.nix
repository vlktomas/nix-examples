{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.ant-dateutils;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
