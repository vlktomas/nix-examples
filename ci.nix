{ pkgs ? import <nixpkgs> {} }:

with pkgs.stdenv.lib;

let
  jobs = rec {

    # all examples CI jobs
    examples = {

      # desktop
      desktopCHello = import ./desktop/C/hello/ci.nix {};
      desktopGoHello = import ./desktop/Go/hello/ci.nix {};
      desktopHaskellAnswer = import ./desktop/Haskell/answer/ci.nix {};
      #FIXME broken build
      #desktopHaskellAnswerGenerated = import ./desktop/Haskell/answer-generated/ci.nix {};
      desktopJavaAntDateUtils = import ./desktop/Java/ant-dateutils/ci.nix {};
      desktopJavaGsGradle = import ./desktop/Java/gs-gradle/ci.nix {};
      desktopJavaSpringBoot = import ./desktop/Java/spring-boot/ci.nix {};
      #desktopJavaScriptCowsay = import ./desktop/JavaScript/cowsay/ci.nix {};
      #desktopJavaScriptCowsayFod = import ./desktop/JavaScript/cowsay-fod/ci.nix {};
      desktopPhpHelloPdf = import ./desktop/PHP/hello-pdf/ci.nix {};
      #desktopPhpLaravelCli = import ./desktop/PHP/laravel-cli/ci.nix {};

      # distributed
      # TODO

      # mobile
      #mobileAndroidCardView = import ./mobile/Android/cardview/ci.nix;
      #mobileAndroidMyfirstapp = import ./mobile/Android/myfirstapp/ci.nix;

      # multitier
      # TODO

      # web
      #webLaravel = import ./web/laravel/ci.nix;

    };

    # all builds
    examplesBuilds = forEach (attrValues examples) (example: example.build);
    #examplesBuilds = catAttrs "build" (attrValues examples);

    # all builds attribute set (something like repository of all examples)
    examplesBuildsAttrSet = mapAttrs (name: value: value.build) examples;

    # all pipelines
    examplesPipelines = forEach (attrValues examples) (example: example.pipeline);
    #examplesPipelines = catAttrs "pipeline" (attrValues examples);

  };
in
  jobs

