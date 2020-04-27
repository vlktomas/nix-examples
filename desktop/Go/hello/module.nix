{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.hello;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
