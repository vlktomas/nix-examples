# How to start a new project

Disclaimer: This is not an official guide how to use Nix in your project. These are just my own personal recommendations.

This file contains a detailed step by step guide how to create a new project similar to the examples in this repository based on this template. The guide supposes that you have installed Nix and you have some basic notion of Nix, NixOS and NixOps. If you don't know what Nix is, please refer to [Nix manual](https://nixos.org/nix/manual/) and read at least some basic info about it.

Template contains nine `.nix` files and deploy script `cicd.sh`:

* `app.nix`
* `nixpkgs.nix`
* `default.nix`
* `shell.nix`
* `ci.nix`
* `module.nix`
* `cd.nix`
* `cd-*.nix`
* `cicd.sh`

In these files you can find many comments which explain how to use it. The following sections describe the purpose of these files and how the created project can be used.

### app.nix -- the app derivation

In this file you have to create an app derivation as a function which takes dependencies from Nixpkgs as arguments. It should be created with common conventions (using `mkDerivation` function, specifing `buildPhase` and so on). How this can be done for vairious technologies is presented by examples in this repository.

Let's say that you want to create Java app built with gradle. Then you look at [app.nix](https://github.com/vlktomas/nix-examples/blob/master/desktop/Java/gs-gradle/app.nix) of gradle example and just modify:

* `pname` attribute -- name of app
* `version` attribute -- version of app
* `src` attribute -- path to source files. It can be swtiched between actual directory files or remote files (argument `localFiles`).
* `meta` attributes -- homepage, maintainer, descripion etc.

to your needs. If your build process is different, you can of course modify `buildPhase`, `installPhase` and so on.

If your project language or build system is not in examples, then you can:

* search in [Nixpkgs manual -- Language and frameworks](https://nixos.org/nixpkgs/manual/#chap-language-support)
* search for similar project in [Nixpkgs repository](https://github.com/NixOS/nixpkgs)
* open issue in this repository
* ask someone or try to do it by yourself

### nixpkgs.nix -- the pin of Nixpkgs

Here you can specify an exact version of Nixpkgs repository, so the build of your package is reproducible. At the beginning of this file you can find some comments which show how this can be specified. Actually there must be defined `defaultNixpkgsSource` attribute which contains the path to Nixpkgs repository. For example:

```nix
let
  # use remote Nixpkgs tarball
  defaultNixpkgsSource = fetchTarball https://github.com/NixOS/nixpkgs/archive/20.03.tar.gz;

  # use local Nixpkgs tarball
  defaultNixpkgsSource = fetchTarball file:///absolute/path/to/nixpkgs/tarball;

  # find first Nixpkgs tarball in parent directories
  findResult = (import <nixpkgs/lib>).filesystem.locateDominatingFile "(nixpkgs.*\.gz)" ./.;
  path = builtins.toString findResult.path;
  file = builtins.elemAt (builtins.elemAt findResult.matches 0) 0;
  defaultNixpkgsSource = fetchTarball "file://${path}/${file}";

  # use Nixpkgs directory
  defaultNixpkgsSource = "/absolute/path/to/nixpkgs/directory";
in
  {
    # ...
  }
```

Next, the app derivation is added to Nixpkgs as `appPackageName`.

```nix
{
  # ...

    overlays = [
      (self: super: {
          # add this app to pkgs
          "${appPackageName}" = super.callPackage ./app.nix { inherit localFiles; };
        })
      ];
    ];

  # ...

  appPackageName = "example";

  # ...
}
```

It means that your package will be placed in Nixpkgs as `example` package, so you can refer to it as `pkgs.example`. You can modify this package name but it isn't really neccessary if you never mind.

If you need to have multiple packages in your project, then you have to create multiple package attributes and add this packages to Nixpkgs. So you do something like this:

```nix
{
  # ...

    overlays = [
      (self: super: {
        # add server app to pkgs
        "${appServerPackageName}" = super.callPackage ./app.nix { inherit localFiles; };

        # add client app to pkgs
        "${appClientPackageName}" = super.callPackage ./app.nix { inherit localFiles; };
      })
    ];

  # ...

  appServerPackageName = "server";
  appClientPackageName = "client";

  # ...
}

```

### default.nix -- call package from Nixpkgs

You don't have to modify this file. It just imports pinned Nixpkgs repository and selects app package from there. It's here for the command `nix-build` to work without additional arguments.

### shell.nix -- create development environment for package

You probably don't have to modify this file. It just specifies dependencies and shell hook for `nix-shell` command. The dependencies present in development environment are simply dependencies of app specified in app derivation. But you can specify some additional dependencies, like editor, linter and so on.

If there is missing some environment variable or you want to execute something when you enter the development environment, you can modify `shellHook` attribute.

See also [direnv](https://direnv.net/) and [lorri](https://github.com/target/lorri).

### ci.nix -- continuous integration jobs

File `ci.nix` contains a set of available jobs for CI as an attribute set. In this template's `ci.nix` there is a comprehesive list of what can be done with Nix but not all you will need and not all can be even used for your project. Feel free to remove or create your own CI jobs.

There is also a simple CI pipeline created with Nix, so in CI tool all you need is to execute is command:

```bash
nix-build ci.nix -A pipelineJob
```

You can find an example of the configuration for some CI/CD tools in this directory, but beware that NixOS testing will not work in those, which use virtual machines or Docker.

### module.nix -- app NixOS module

This file contains NixOS system configuration needed to use your app. It can be used to create some directories or to register your app as systemd unit. If your project is desktop app, all you will probably want to have in this file is to add your app as system package. If your project is for example a web app, you will probably want to specify some module options like domain name and so on.

Please refer to [NixOS manual](https://nixos.org/nixos/manual/) for more info of how to create NixOS module.

### cd.nix -- logical deployment specification

It is possible to use Nix to describe an infrastructure for your project. Thr infrastructure can be composed of multiple servers (database server, web server, ...) or just one machine which imports `module.nix`. It is simply attribute set of NixOS configurations.. This infrastructure can be used to system tests (NixOS tests) or to deploy to real machines.

### cd-*.nix -- physical deployment specification for NixOps

The previous file `cd.nix` is a logical specification of the instrastructure. If you want to use NixOps to deploy this infrastructure specification to real hardware, you have to therefore specify some additional attributes like IP address, Amazon resources and so on. Physical aspects of the infrastructure should be in `cd-*.nix` files. For instance you can create `cd-vbox.nix` and deploy the whole infrastracture to VirtualBox, or you can create `cd-production.nix` and `cd-test.nix` files and deploy the production infrastructure to Amazon and the testing infrastructure to your hardware running NixOS.

NixOps can work with secret data (passwords, private keys, ...) in a way that they will not get into `/nix/store`. These are specified by special attributes `delpoyment.keys` which aren't in NixOS configuration. Because of that these attributes cannot be in `cd.nix` and should be stored in `cd-*.nix`. Otherwise you won't be able to use `cd.nix` to system tests.

Please refer to [NixOps manual](https://nixos.org/nixops/manual/) for more info of how to use NixOps.

### cicd.sh -- run CI/CD

This file is a simple script which basically wrap these commands:

```bash
nix-build ci.nix -A pipelineJob
nixops deploy
```

So in your CI/CD tool you can execute just:

```bash
./cicd.sh
```

There is also an option to run the infrastructure in VirtualBox (based on `cd-vbox.nix`) and execute some commands on it, a.k.a deployment test. It can be executed using:

```bash
./cicd.sh deploy-test
```

## How to use a new project

Build project:
```bash
nix-build
```

You can switch from local files to remote files:
```bash
nix-build --arg localFiles false
```

You can build the project with different Nixpkgs:
```bash
nix-build --arg nixpkgsSource "<nixpkgs>"
nix-build --arg nixpkgsSource "/absolute/path/to/nixpkgs/directory"
```

Enter development shell (you can use the same arguments as above):
```bash
nix-shell
```

Run CI pipeline and gather all phases outputs to `result` symlink:
```bash
nix-build ci.nix -A pipelineJob
```

Run CI pipeline and create for each phase own `result` symlink:
```bash
nix-build ci.nix -A pipeline
```

Run CI pipeline up to second phase (numbered from zero):
```bash
nix-build ci.nix -A pipeline.1
```

Run CI pipeline up to "test" phase:
```bash
nix-build -E 'builtins.filter (phase: phase.name == "phase-test") (import ./ci.nix {}).pipeline'
```

Run only some CI job:
```bash
nix-build ci.nix -A job
```

Run only some CI job with no out link:
```bash
nix-build ci.nix -A job --no-out-link
```

Test NixOps deployment in VirtualBox
```bash
./cicd.sh deploy-test
```

Run CI pipeline and deploy with NixOps
```bash
./cicd.sh
```

