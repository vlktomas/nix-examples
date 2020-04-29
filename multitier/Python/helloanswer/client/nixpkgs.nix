{ nixpkgsSource ? null, localFiles ? true }:

let
  nixpkgs = import ../nixpkgs.nix { inherit nixpkgsSource localFiles; };
in
  nixpkgs // {
    appPackage = nixpkgs.clientPackage;
    appPackageName = nixpkgs.clientPackageName;
  }
