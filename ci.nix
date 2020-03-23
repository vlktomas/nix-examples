{ pkgs ? import <nixpkgs> {} }:

with pkgs.stdenv.lib;

let
  jobs = rec {

    # all examples CI jobs

    # desktop
    desktopCHello = import ./desktop/C/hello-2.10/ci.nix {};
    desktopGoHello = import ./desktop/Go/hello/ci.nix {};
    desktopHaskellAnswer = import ./desktop/Haskell/answer/ci.nix {};
    desktopHaskellAnswerGenerated = import ./desktop/Haskell/answer-generated/ci.nix {};
    desktopJavaAntDateUtils = import ./desktop/Java/AntDateUtils/ci.nix {};
    desktopJavaGsGradle = import ./desktop/Java/gs-gradle/ci.nix {};
    desktopJavaSpringBoot = import ./desktop/Java/SpringBoot/ci.nix {};
    desktopJavaScriptCowsay = import ./desktop/JavaScript/cowsay-1.4.0/ci.nix {};
    desktopJavaScriptCowsayFod = import ./desktop/JavaScript/cowsay-1.4.0-fod/ci.nix {};
    desktopPhpHelloPdf = import ./desktop/PHP/hello-pdf/ci.nix {};
    desktopPhpLaravelCli = import ./desktop/PHP/laravel-cli/ci.nix {};

    # distributed
    # TODO

    # mobile
    mobileAndroidCardView = import ./mobile/Android/CardView/ci.nix;
    mobileAndroidMyfirstapp = import ./mobile/Android/myfirstapp/ci.nix;

    # multitier
    # TODO

    # web
    webLaravel = import ./web/laravel/ci.nix;

    # all examples
    examples = [
      desktopCHello
      desktopGoHello
      desktopHaskellAnswer
      #desktopHaskellAnswerGenerated # FIXME broken
      desktopJavaAntDateUtils
      desktopJavaGsGradle
      desktopJavaSpringBoot
      #desktopJavaScriptCowsay
      #desktopJavaScriptCowsayFod
      desktopPhpHelloPdf
      #desktopPhpLaravelCli
      #mobileAndroidCardView
      #mobileAndroidMyfirstapp
      #webLaravel
    ];

    # all builds (something like repository of all examples)
    examplesBuild = forEach examples (example: example.build);

    # all pipelines
    examplesPipelines = forEach examples (example: example.pipeline);

    # example of combining of multiple pipelines into one
    # first and second pipelines are executed independently and third pipeline
    # is executed only if both of pipelines are successful
    integrationPipeline =
      let
        firstPipeline = desktopCHello.pipeline;
        secondPipeline = desktopGoHello.pipeline;
        thirdPipeline = desktopPhpHelloPdf.pipeline;
      in
        mkPipeline' (map last [ firstPipeline secondPipeline ]) thirdPipeline;

    mkPipeline = mkPipeline' null;
    mkPipeline' = prev: phases: foldl mkDependency prev phases;
    mkDependency = prev: next: next.overrideAttrs (oldAttrs: { prev = prev; });

  };
in
  jobs

