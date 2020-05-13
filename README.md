# nix-examples (Work In Progress!)

This repository serves as comprehensive list of Nix examples for various technologies. The main goal of these examples is to be as simple as possible, has the same interface and demonstrate possibilities of Nix. Note that examples are created only with official tools available in Nixpkgs. Some examples could be done better with unofficial tools, but using the most efficient solution at any cost is not purpose of these examples.

Each project contains from five to nine `.nix` files and optionally deploy script `cicd.sh`:

* `nixpkgs.nix` -- pin of Nixpkgs and its configuration and add app as overlay
* `app.nix` -- app derivation (can be easily integrated into Nixpkgs tree or own packages tree)
* `default.nix` -- calls package from pinned Nixpkgs
* `shell.nix` -- similar to `default.nix`, but overriding some attributes or adding some dev tools
* `ci.nix` -- set of available CI jobs
* `module.nix` -- app as NixOS module (can be easily integrated into NixOS modules tree or own modules tree)
* `cd.nix` -- logical deployment specification (independent of NixOps)
* `cd-*.nix` -- physical deployment specification for NixOps (for example `cd-vbox.nix` describe deployment to VirtualBox machines)
* `cicd.sh` -- run Nix for CI pipeline and NixOps for deployment

To start new project just copy `template` directory, which contains these files with additional info. There is also an example configuration for some CI/CD tools, but beware that NixOS testing will not work in those, which use virtual machines or Docker.

## How to use

Install Nix:
```bash
curl https://nixos.org/nix/install | sh
```

Build all examples:
```bash
nix-build -A examplesBuilds
```

Run all examples CI pipelines (memory intensive):
```bash
nix-build -A examplesPipelinesJobs
```

Run all examples CI pipelines up to second phase (numbered from zero):
```bash
nix-build -A examplesPipelinesZipped.1
```

Run all examples CI pipelines up to "test" phase:
```bash
nix-build -E '(import ./default.nix).examplesPipelinePhase "test"'
```

### How to use each example 

Build project:
```bash
nix-build
```

You can switch from local files to remote files:
```bash
nix-build --arg localFiles false
```

You can build project with different Nixpkgs:
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

### Project dependencies

There are three ways to get dependencies when using Nix:

 1. Dependencies can be easily specified by its name in Nix file (dependencies in Nixpkgs).
 2. Dependencies derivations can be generated from some file. For example for NPM you can use `node2nix`.
 3. All dependencies must be treated as one single derivation (Fixed Output Derivation).

Overview of available ways of getting dependencies in examples by dependency tool is in following table:

| Dependency tool  | dependencies in Nixpkgs | dependencies derivations generated | dependencies as one derivation (FOD) |
|-------------     |:-----------------------:|:----------------------------------:|:------------------------------------:|
| Autotools        | :heavy_check_mark:      | --                                 | --                                   |
| Go modules       | --                      | --                                 | :heavy_check_mark:                   |
| Cabal            | :heavy_check_mark:      | :heavy_check_mark:                 | --                                   |
| Maven            | --                      | --                                 | :heavy_check_mark:                   |
| Gradle           | --                      | --                                 | :heavy_check_mark:                   |
| NPM              | --                      | :heavy_check_mark:                 | :heavy_check_mark:                   |
| Composer         | --                      | --                                 | :heavy_check_mark:                   |
| Pip              | :heavy_check_mark:      | --                                 | --                                   |

## Notes

 * This repo contains source code of common public projects as is. Source files are included in repo only for convenience. If you think that it's violating some license rules please let me know. But keep in mind that this is not real project, included source files are not used for commercial reasons.

 * Some source code of projects had to be a little bit modified. For example JavaScript cowsay repo does not contain `package-lock.json`, so this file was added. See [Example specific notes](#example-specific-notes) below for other changes.

 * Each example is self contained and does not have dependency on other files out of its folder. So a lot of code is repeating but it is intentional.

 * In Nix, arguments of package are not distinguished. The examples follow convention that, dependencies are listed first, and then the other arguments.

 * Each project has boolean arg `localFiles`, which switches between sources from remote repository and local files. But most of the projects do not have own repository, so remote sources fetching will not work.

 * There is copy of `nixpkgs-20.03.tar.gz` included in repo. It is to keep examples working even if Nixpkgs will be completely changed in future.

 * This project was created as part of my thesis at Brno University of Technology.

 * Any help or feedback is really appreciated.

### Example specific notes:

- `desktop/C/hello`
    - Source: [https://www.gnu.org/software/hello/](https://www.gnu.org/software/hello/)

- `desktop/G/hello`
    - Source: [https://github.com/golang/go/wiki/Modules](https://github.com/golang/go/wiki/Modules)

- `desktop/Haskell/answer`
    - Source: [https://github.com/shajra/example-nix](https://github.com/shajra/example-nix)

- `desktop/Haskell/answer-generated`
    - Source: [https://github.com/shajra/example-nix](https://github.com/shajra/example-nix)

- `desktop/Java/ant-dateutils`
    - Source: [https://www.mkyong.com/ant/ant-how-to-create-a-java-project/](https://www.mkyong.com/ant/ant-how-to-create-a-java-project/)
    - Project was modified to print current year instead of current date.

- `desktop/Java/gs-gradle`
    - Source: [https://github.com/spring-guides/gs-gradle](https://github.com/spring-guides/gs-gradle)

- `desktop/Java/spring-boot`
    - Source: [https://start.spring.io/](https://start.spring.io/)

- `desktop/JavaScript/cowsay`
    - Source: [https://github.com/piuccio/cowsay](https://github.com/piuccio/cowsay)
    - Project does not contain `package-lock.json`, so it was added.
    - In `package.json` was removed `rollup -c` from prepublish script.

- `desktop/JavaScript/cowsay-fod`
    - Source: [https://github.com/piuccio/cowsay](https://github.com/piuccio/cowsay)
    - Project does not contain `package-lock.json`, so it was added.
    - In `package.json` was removed `rollup -c` from prepublish script.

- `desktop/PHP/hello-pdf`
    - Source: [https://github.com/svanderburg/composer2nix](https://github.com/svanderburg/composer2nix)
    - To reproducible build of dependencies, specify the `autoloader-suffix` in `composer.json`.

- `desktop/PHP/laravel-cli`
    - Files in `database` must be present when getting dependencies.
    - To reproducible build of dependencies, specify the `autoloader-suffix` in `composer.json`.

- `distributed/Spark/pi`
    - Inspired by: [Big Data Cloud Computing Infrastructure Framework](https://projekter.aau.dk/projekter/files/313620564/dt107f19_Master_thesis.pdf)
    - Example Spark Pi estimation is from [http://spark.apache.org/examples.html](http://spark.apache.org/examples.html)

- `mobile/Android/cardview`
    - Source: [https://github.com/android/views-widgets-samples/tree/master/CardView/](https://github.com/android/views-widgets-samples/tree/master/CardView/)
    - To use Android SDK you must set `android_sdk.accept_license = true;` in Nixpkgs config.

- `mobile/Android/myfirstapp`
    - Source: [https://github.com/svanderburg/nix-androidenvtests](https://github.com/svanderburg/nix-androidenvtests)
    - To use Android SDK you must set `android_sdk.accept_license = true;` in Nixpkgs config.

- `web/Laravel/laravel`
    - Files in `database` must be present when getting dependencies.
    - To reproducible build of dependencies, specify the `autoloader-suffix` in `composer.json`.
    - When deploying Laravel web apps, there is problem with storage path. Unfortunately in Laravel it is not easy to set storage path via `.env`. Changing of `storage_path` in config is not enough, because storage path must be set before config is loaded at all. So you must create `app/Foundation/Application.php` class which extends original Laravel `Application.php` class, in which you change `storage_path`. Next you set new `Application.php` in `bootstrap/app.php` and finally you can specify `APP_STORAGE_PATH` in `.env`.
    - If local database is used, then user is authenticated via socket authentication. For this reason, in `.env.example` file variable `DB_SOCKET` was added.

## References

* [Nix manual](https://nixos.org/nix/manual/)
* [Nixpkgs manual](https://nixos.org/nixpkgs/manual/)
* [Nixops manual](https://nixos.org/nixops/manual/)
* [Nix Pills](https://nixos.org/nixos/nix-pills/)
* [NixOS wiki](https://nixos.wiki/)
* [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)
* [nix-community/nixos-generators](https://github.com/nix-community/nixos-generators)
* [Managing Projects with Nix - Tokyo NixOS Meetup](https://github.com/Tokyo-NixOS/presentations/tree/master/2017/02/)

## License

Each example project may has own licence. All other things in this repo are licensed under GNU/GPL:

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.

