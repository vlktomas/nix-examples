{ pkgs ? import <nixpkgs> {} }:

(import ./ci.nix { inherit pkgs; }).examplesBuilds

