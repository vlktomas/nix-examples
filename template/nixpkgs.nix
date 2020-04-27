# pin nixpkgs to specific version
let
  # use remote Nixpkgs tarball
  defaultNixpkgsSource = fetchTarball https://github.com/NixOS/nixpkgs/archive/20.03.tar.gz;

  # use local Nixpkgs tarball
  #defaultNixpkgsSource = fetchTarball file:///absolute/path/to/nixpkgs/tarball;

  # find first Nixpkgs tarball in parent directories
  #findResult = (import <nixpkgs/lib>).filesystem.locateDominatingFile "(nixpkgs.*\.gz)" ./.;
  #path = builtins.toString findResult.path;
  #file = builtins.elemAt (builtins.elemAt findResult.matches 0) 0;
  #defaultNixpkgsSource = fetchTarball "file://${path}/${file}";

  # use Nixpkgs directory
  #defaultNixpkgsSource = "/absolute/path/to/nixpkgs/directory";
in
  { nixpkgsSource ? null, localFiles ? true }:
  let
    nixpkgs =
      if nixpkgsSource != null then
        nixpkgsSource
      else
        defaultNixpkgsSource;
  in
    rec {
      lib = import "${nixpkgs}/lib";
      nixos = import "${nixpkgs}/nixos";
      pkgs = import nixpkgs {
        # we can enforce nixpkgs configuration for making config pure
        config = { };

        # we can specify multiple overlays for adding/modifying packages
        overlays = [
          (self: super:
          {
            # add this app to pkgs
            "${appPackageName}" = super.callPackage ./app.nix { inherit localFiles; };
          })
        ];
      };
      appPackage = pkgs."${appPackageName}";
      # provides package name under which app is registered in Nixpkgs
      appPackageName = "example";
      # get Nixpkgs path when converting to string
      outPath = "${nixpkgs}";
    }
