with import <nixpkgs/lib>;

rec {

  # all examples CI jobs
  examples = {

    # desktop
    desktopCHello = import ./desktop/C/hello/ci.nix {};
    desktopGoHello = import ./desktop/Go/hello/ci.nix {};
    desktopHaskellAnswer = import ./desktop/Haskell/answer/ci.nix {};
    desktopHaskellAnswerGenerated = import ./desktop/Haskell/answer-generated/ci.nix {};
    desktopJavaAntDateUtils = import ./desktop/Java/ant-dateutils/ci.nix {};
    desktopJavaGsGradle = import ./desktop/Java/gs-gradle/ci.nix {};
    # FIXME not always reproducible
    desktopJavaSpringBoot = import ./desktop/Java/spring-boot/ci.nix {};
    # FIXME not always reproducible
    desktopJavaScriptCowsay = import ./desktop/JavaScript/cowsay/ci.nix {};
    # FIXME not always reproducible
    desktopJavaScriptCowsayFod = import ./desktop/JavaScript/cowsay-fod/ci.nix {};
    desktopPhpHelloPdf = import ./desktop/PHP/hello-pdf/ci.nix {};
    # FIXME not always reproducible
    desktopPhpLaravelCli = import ./desktop/PHP/laravel-cli/ci.nix {};

    # distributed
    # TODO

    # mobile
    mobileAndroidCardview = import ./mobile/Android/cardview/ci.nix {};
    mobileAndroidMyfirstapp = import ./mobile/Android/myfirstapp/ci.nix {};

    # multitier
    multitierPythonHelloanswer = import ./multitier/Python/helloanswer/ci.nix {};

    # web
    # FIXME not always reproducible
    webLaravel = import ./web/Laravel/ci.nix {};

  };

  # all builds
  examplesBuilds = forEach (attrValues examples) (example: example.build);
  #examplesBuilds = catAttrs "build" (attrValues examples);

  # all builds attribute set (something like repository of all examples)
  examplesBuildsAttrSet = mapAttrs (name: value: value.build) examples;

  # all pipelines
  examplesPipelines = forEach (attrValues examples) (example: example.pipeline);
  #examplesPipelines = catAttrs "pipeline" (attrValues examples);

  # all pipelines jobs
  examplesPipelinesJobs = forEach (attrValues examples) (example: example.pipelineJob);
  #examplesPipelines = catAttrs "pipelineJob" (attrValues examples);

  # all pipelines phases merged
  examplesPipelinesZipped =
    let
      zipPipelines = a: b:
        if a == [] then
          b
        else
          zipListsWith (x: y: flatten [ x y ]) a b;
    in
      foldl zipPipelines [] examplesPipelines;

  # all pipelines phase of given name (each phase has dependency on all preceding phases)
  examplesPipelinePhase = phaseName:
    flatten (
      forEach
        (attrValues examples)
        (example:
          filter
            (phase: phase.name == "phase-${phaseName}")
            example.pipeline
        )
    );

}
