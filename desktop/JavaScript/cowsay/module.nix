{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.cowsay;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
