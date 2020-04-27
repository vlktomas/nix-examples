{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.hello-pdf;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
