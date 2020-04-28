{ config, lib, pkgs, ... }:

with lib;

let
  pkg = pkgs.answer-generated;
in
  {
    config = {
      environment.systemPackages = [ pkg ];
    };
  }
