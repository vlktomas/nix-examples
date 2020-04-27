let
  defaultNixpkgsSource = fetchTarball https://github.com/NixOS/nixpkgs/archive/20.03.tar.gz;
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
        config = { };
        overlays = [
          (self: super:
          {
            "${appPackageName}" = super.callPackage ./app.nix { inherit localFiles; };
          })
        ];
      };
      appPackage = pkgs."${appPackageName}";
      appPackageName = "laravel";
      outPath = "${nixpkgs}";
    }

