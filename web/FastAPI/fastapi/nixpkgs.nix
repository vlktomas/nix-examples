let
  # Commit hash for nixos-unstable as of 2021-10-28, the 20.09 release doesn't work for some reason
  defaultNixpkgsSource = fetchTarball https://github.com/nixos/nixpkgs/archive/22a500a3f87bbce73bd8d777ef920b43a636f018.tar.gz;
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
          (self: super: {
            "${appPackageName}" = super.callPackage ./app.nix { inherit localFiles; };
          })
        ];
      };
      appPackage = pkgs."${appPackageName}";
      appPackageName = "fastapi";
      outPath = "${nixpkgs}";
    }

