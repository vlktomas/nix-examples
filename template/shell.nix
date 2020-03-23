{ pkgs ? import ./nixpkgs.nix }:

# this file only override default.nix

# in default.nix you can also use pkgs.lib.inNixShell and specify some
# derivation attributtes conditionally, if you do not want use this file

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  app.overrideAttrs (oldAttrs: {
    src = null; 
    # we can add some developement only tools as dependency
    #nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.cowsay ];
  })

