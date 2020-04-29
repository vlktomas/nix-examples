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
          (self: super: rec {
            python3 = super.python3.override {
              # Careful, we're using a different self and super here!
              packageOverrides = pythonSelf: pythonSuper: {
                 "${answerlibPackageName}" = pythonSuper.callPackage ./answerlib/app.nix { inherit localFiles; };
                 "${hellolibPackageName}" = pythonSuper.callPackage ./hellolib/app.nix { inherit localFiles; };
              };
            };
            python3Packages = python3.pkgs;

            "${serverPackageName}" = super.callPackage ./server/app.nix { inherit localFiles; };
            "${clientPackageName}" = super.callPackage ./client/app.nix { inherit localFiles; };
          })
        ];
      };
      serverPackage = pkgs."${serverPackageName}";
      serverPackageName = "server";
      clientPackage = pkgs."${clientPackageName}";
      clientPackageName = "client";
      answerlibPackage = pkgs.python3Packages."${answerlibPackageName}";
      answerlibPackageName = "answerlib";
      hellolibPackage = pkgs.python3Packages."${hellolibPackageName}";
      hellolibPackageName = "hellolib";
      outPath = "${nixpkgs}";
    }
