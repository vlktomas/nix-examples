{
  # dependencies
  stdenv, androidenv, fetchurl, nix-gitignore,

  # args
  localFiles ? false,
  release ? true
}:

androidenv.buildApp {
  name = "myfirstapp";

  src = (
    if localFiles then
      nix-gitignore.gitignoreSource [ "result" ] ./.
    else
      fetchurl {
        url = "https://example.com";
        sha256 = stdenv.lib.fakeSha256;
      }
  );

  inherit release;

  # If release is set to true, you need to specify the following parameters
  keyStore = ./keystore;
  keyAlias = "myfirstapp";
  keyStorePassword = "mykeystore";
  keyAliasPassword = "myfirstapp";

  # Any Android SDK parameters that install all the relevant plugins that a
  # build requires
  platformVersions = [ "28" ];

  # When we include the NDK, then ndk-build is invoked before Ant gets invoked
  includeNDK = false;
}

