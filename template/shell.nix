{ pkgs ? (import ./nixpkgs.nix).pkgs }:

# this file only overrides default.nix

# if you do not want use this file, you can also use pkgs.lib.inNixShell 
# in default.nix and specify some derivation attributtes conditionally

let 
  app = import ./default.nix { inherit pkgs; localFiles = true; };
in
  pkgs.mkShell {
    inputsFrom = [ app ];
    src = null;
    # we can add some developement only tools as dependency
    buildInputs =  with pkgs; [ cowsay ];
  }
  # but in expression above we can't specify shellHook,
  # so to specify also shellHook use this:
  /*
  app.overrideAttrs (oldAttrs: {
    src = null; 
    # we can add some developement only tools as dependency
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.cowsay ];
    shellHook = 
      ''
        export ANSWER="42"
      '';
  })
  */

