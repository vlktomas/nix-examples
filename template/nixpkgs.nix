# pin nixpkgs to specific version
let
  # use remote Nixpkgs tarball
  source = fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz;

  # use local Nixpkgs tarball
  #source = fetchTarball file:///absolute/path/to/nixpkgs/tarball;

  # find first Nixpkgs tarball in parent directories
  #findResult = (import <nixpkgs/lib>).lib.filesystem.locateDominatingFile "(nixpkgs.*\.gz)" ./.;
  #path = builtins.toString findResult.path;
  #file = builtins.elemAt (builtins.elemAt findResult.matches 0) 0;
  #source = fetchTarball "file://${path}/${file}";
in
  {
    pkgs = import source {
      # we can enforce nixpkgs configuration for making config pure
      config = { };
      
      /*
      # we can specify overlays for adding/modifying packages
      overlays = [
        (self: super:
        {
          my-hello = super.callPackage ./app.nix { fetchSources = false; };
        })
      ];
      */
    };
    nixos = import "${source}/nixos";
  }

