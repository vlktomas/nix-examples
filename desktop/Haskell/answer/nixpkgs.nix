# pin nixpkgs to specific version
import (fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz) {
  # we can enforce nixpkgs configuration for making config pure
  config = { };
  
  # we can specify overlays for adding/modifying packages
  #overlays = [
  #  (self: super:
  #  {
  #    my-hello = super.callPackage ./app.nix { fetchSources = false; };
  #  })
  #];

  # for overriding Haskell packages
  #packageOverrides = pkgs: rec {
  #  haskellPackages = pkgs.haskellPackages.override {
  #    overrides = haskellPackagesNew: haskellPackagesOld: rec {
  #      turtle =
  #        # we can generate nix file for some Haskell package with: cabal2nix cabal://turtle-1.3.2 > turtle.nix
  #        haskellPackagesNew.callPackage ./turtle.nix { }; 
  #    };
  #  };
}

