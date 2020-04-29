{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.answer;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
