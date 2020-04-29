{ nixpkgsSource ? null, localFiles ? true }:

let
  nixpkgs = import ../nixpkgs.nix { inherit nixpkgsSource localFiles; };
in
  nixpkgs // {
    appPackage = nixpkgs.answerlibPackage;
    appPackageName = nixpkgs.answerlibPackageName;
  }
