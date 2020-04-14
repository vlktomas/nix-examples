# pin nixpkgs to specific version
let
  source = fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz;
in
  {
    pkgs = import source {
      config = { };
    };
    nixos = import "${source}/nixos";
  }

