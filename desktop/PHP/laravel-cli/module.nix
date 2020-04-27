{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.laravel-cli;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
