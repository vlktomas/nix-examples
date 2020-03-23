# pin nixpkgs to specific version
import (fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz) {
  # we can enforce nixpkgs configuration for making config pure
  config = {
    android_sdk.accept_license = true;
  };
  
  # we can specify overlays for adding/modifying packages
  #overlays = [
  #  (self: super:
  #  {
  #    my-hello = super.callPackage ./app.nix { fetchSources = false; };
  #  })
  #];
}

