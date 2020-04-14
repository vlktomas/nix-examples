{
  server = {

    nixpkgs.pkgs = (import ./nixpkgs.nix).pkgs;

    imports = [
      ./module.nix
    ];

  };
}
