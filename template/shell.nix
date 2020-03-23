{ pkgs ? import ./nixpkgs.nix }:

# this file only overrides default.nix

# if you do not want use this file, you can also use pkgs.lib.inNixShell 
# in default.nix and specify some derivation attributtes conditionally

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  app.overrideAttrs (oldAttrs: {
    src = null; 
    # we can add some developement only tools as dependency
    #nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.cowsay ];
  })

