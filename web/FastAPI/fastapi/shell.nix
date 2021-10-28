{ nixpkgsSource ? null }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage;
in
  with pkgs;

  (poetry2nix.mkPoetryEnv {
    projectDir = ./.;
    python = python39;
    editablePackageSources = {
      app = ./app;
    };
  }).env.overrideAttrs (oldAttrs: {
    # poetry is not listed in dev-dependencies
    # requests is missing in pytest dependencies
    buildInputs = [ poetry python39Packages.requests ];
  })

