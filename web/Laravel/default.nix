{ pkgs ? import ./nixpkgs.nix,
  localFiles ? true,
  appKey ? "",
  appStoragePath ? "storage",
  dbHost ? "127.0.0.1",
  dbPort ? "3306",
  dbSocket ? "",
  dbName ? "example",
  dbUsername ? "root",
  dbPassword ? ""
}:

with pkgs; callPackage ./app.nix { inherit localFiles appKey appStoragePath dbHost dbPort dbSocket dbName dbUsername dbPassword; }

