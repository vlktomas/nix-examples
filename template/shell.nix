{ nixpkgsSource ? null }:

# this file is very similar to default.nix

# if you do not want use this file, you can also use lib.inNixShell
# in app.nix and specify some derivation attributtes conditionally

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage;
in
  pkgs.mkShell {
    inputsFrom = [ appPackage ];
    src = null;
    # we can add some developement only tools as dependency
    buildInputs = with pkgs; [ cowsay ];
    shellHook = ''
      export ANSWER="42"
    '';
  }
  # or
  /*
  example.overrideAttrs (oldAttrs: {
    src = null;
    # we can add some developement only tools as dependency
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ cowsay ];
    shellHook = ''
      export ANSWER="42"
    '';
  })
  */
