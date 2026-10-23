# Nix tooling for Flakes and BEAM Languages

**Table of Contents**

<!-- vim-markdown-toc Marked -->

- [Project Status](#project-status)
- [Requirements](#requirements)
- [Features](#features)
  - [Packages](#packages)
    - [phx_new](#phx_new)
    - [livebook](#livebook)
- [Usage](#usage)
  - [Via Flake Template](#via-flake-template)
  - [Manually Via `flake-parts`](#manually-via-flake-parts)
- [Setting Versions](#setting-versions)
  - [Explicitly](#explicitly)
  - [`.tool-versions` Compatibility](#tool-versions-compatibility)
- [Future Plans](#future-plans)
- [Contributing](#contributing)
  - [Newly-published language versions](#newly-published-language-versions)
  - [Other Beam Languages](#other-beam-languages)
  - [Other Details](#other-details)
- [Credits](#credits)

<!-- vim-markdown-toc -->

## Project Status

> [!WARNING]
> This is a maintained fork of [shanesveller/nix-beam-flakes](https://github.com/shanesveller/nix-beam-flakes). See [issue #53](https://github.com/shanesveller/nix-beam-flakes/issues/53) on the original repo. If the original returns to maintenance, I will deprecate this fork.

## Requirements

- Nix with Flakes support
- [flake-parts](https://github.com/hercules-ci/flake-parts)
- `direnv` (Optional)

## Features

- Automatic packaging for ~any finalized, tagged release of both Erlang/OTP and
  Elixir
  - Package definitions are based on upstream `nixpkgs` definitions with source
    and version overrides, where that Nixpkgs release still has a builder
  - Packages will be added to your own flake's outputs, and can be consumed by
    other Nix code
- Declarative, automatic `devShell` creation using these packages (with opt-out)
  - Opt-in support for `elixir-ls` and `erlang_ls` LSP servers
- Elixir-ecosystem-aware Nix helpers
- A small number of Elixir applications usable directly via `nix run` (see below)
- [Flake Templates](#via-template)

### Packages

#### phx_new

Want to start a new Phoenix project? Don't have a global install of Elixir/Mix?
This can help. Pairs well with flake templates below.

```shell
nix run github:cigrainger/nix-beam-flakes/develop#phx_new -- --help
```

#### livebook

```shell
nix run github:cigrainger/nix-beam-flakes/develop#livebook -- server
```

## Usage

### Via Flake Template

```shell
nix flake init -t github:cigrainger/nix-beam-flakes/develop#default
# or
nix flake init -t github:cigrainger/nix-beam-flakes/develop#phoenix
```

At the time of writing there is no meaningful distinction between the two, but
they will diverge as I continue to implement speciality support for the needs of
a Phoenix project.

### Manually Via `flake-parts`

Please review the documentation for flake-parts [here](https://flake.parts/) if
you are new to this library/paradigm.

A complete example:

```nix
{
  description = "My Elixir application";

  inputs = {
    beam-flakes.url = "github:cigrainger/nix-beam-flakes/develop";
    beam-flakes.inputs.flake-parts.follows = "flake-parts";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = {
    self,
    beam-flakes,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit self;} {
      imports = [beam-flakes.flakeModule];

      systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"];

      perSystem = _: {
        beamWorkspace = {
          enable = true;
          devShell.languageServers.elixir = true;
          versions = {
            elixir = "1.20.1";
            erlang = "29.0.2";
          };
        };
      };
    };
}
```

You can add any additional packages to `perSystem.beamWorkspace.devShell.extraPackages`.
You can provide additional arguments to `mkShell`, such as arbitrary environment
variables, via `perSystem.beamWorkspace.devShell.extraArgs`.
You can opt out of the automatic `default` devShell and manage yourself by
setting `perSystem.beamWorkspace.devShell.enable = false;`

## Setting Versions

### Explicitly

```nix
    flake-parts.lib.mkFlake {inherit self;} {
      # ...
      perSystem = _: {
        beamWorkspace = {
          versions = {
            # You can also use an `asdf`-compatible string, such as "1.14.2-otp-25".
            #
            # Everything after the first hyphen is stripped and handled according
            # to the defined erlang version instead.
            elixir = "1.20.1";
            erlang = "29.0.2";
          };
        };
      };
    };
```

### `.tool-versions` Compatibility

For projects that formerly, or concurrently, use
[asdf](http://github.com/asdf-vm/asdf), a compatibility shim will read your
`.tool-versions` file and set the `elixir` and `erlang` versions accordingly.

```nix
    flake-parts.lib.mkFlake {inherit self;} {
      # ...
      perSystem = _: {
        beamWorkspace = {
          enable = true;
          versions = {
            fromToolVersions = ./.tool-versions;
          };
        };
      };
    };
```

## Future Plans

Immediate concerns:

- [ ] Significant documentation efforts inspired by the `flake-parts` website
- [x] CI that the modules continue to evaluate successfully with common scenarios
- [ ] Credential-gated publishing to an explicitly configured existing cache
- [ ] More robust specialty support for Phoenix projects

Later on:

- [x] Enforce [Elixir's compatibility policy](https://hexdocs.pm/elixir/compatibility-and-deprecations.html)
  when selecting a package set
- Phoenix speciality support
  - `esbuild` binaries
  - `tailwind` binaries
  - Possibly some lightweight Node.js support

Future:

- [pre-commit-hooks.nix](https://github.com/cachix/pre-commit-hooks.nix)
  integration with canned Elixir-specific hooks - it already pairs nicely using the `flake-parts` module
- Automatic Docker-compatible OCI image creation from your Mix release via
  [`pkgs.ociTools`](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-ociTools)
- NixOS module generation to run your Mix release via `systemd`

## Contributing

Generally not solicited at this time, but if you're particularly adventurous,
read on.

### Newly-published language versions

If you are a Nix user, this is already automated:

```shell
nix develop ./dev
just add-elixir 1.20.1
just add-erlang 29.0.2
```

Just PR the changes to `data` that it committed for you. I'll probably be on top
of it already, for the most part.

### Other Beam Languages

At this time I am not a personal or professional user of any other languages
that inhabit the BEAM VM, and I do not feel I can offer a satisfactory level of
support or nuance for tooling I do not use. As such, I will consider
collaborating with those who do to offer support here on a best-effort basis,
but I do not consider it a priority at this time.

### Other Details

Please open an issue/discussion before setting out on any other contributions so
that we can discuss whether your ideas align with my plans for this project. I'd
hate to see anyone feel like their effort/goodwill were wasted.

## Credits

I would not have pushed this very far were it not for flakes and
[flake-parts](https://github.com/hercules-ci/flake-parts). I've gotten several
rounds of useful feedback directly from discussions on the `flake-parts`
repository as well as learned a lot from studying its code.

I also take some inspiration from
[`oxalica/rust-overlay`](https://github.com/oxalica/rust-overlay).

## Current toolchain checks

This is Chris Grainger's fork, `cigrainger/nix-beam-flakes`, on `develop`.
The BEAM packaging changes and release checksums are adapted from
[elixir-tools/nix-beam-flakes at 949f26e](https://github.com/elixir-tools/nix-beam-flakes/commit/949f26e7ad5a85e29d4e0d79649c82b0f399562f)
under the preserved Apache-2.0 license. See [credits](docs/credits.md).

CI targets `aarch64-darwin` (the arm64 `macos-26` runner) and `x86_64-linux`,
and asserts both runner architecture and Nix platform. Each PR evaluates native
regressions and builds/runs the exact approved Elixir `1.20.1-otp-29` / OTP
`29.0.2` pair. This intentionally retained application baseline is separate from
latest stable releases. Historical checksums are an inventory, not a promise
that current Nixpkgs still provides every historical builder. Enumeration skips
removed builders; explicit requests report an error when a builder is absent.

Run the checks on each native host (substitute `x86_64-linux` on Linux):

```sh
nix build -L .#checks.aarch64-darwin.regression .#checks.aarch64-darwin.devshell-interface .#checks.aarch64-darwin.approved-runtime
```

Direct consumers can use the same exact pair without flake-parts:

```nix
beam-flakes.lib.mkPackageSet {
  inherit pkgs;
  elixirVersion = "1.20.1-otp-29";
  erlangVersion = "29.0.2";
}
```

`packageSetFromToolVersions pkgs ./.tool-versions {}` also works. Both helpers
and `beamWorkspace.versions.fromToolVersions` strip the optional Elixir OTP
suffix, use the explicitly selected Erlang version, and preserve requested
source and package version metadata. The parser accepts tabs, repeated spaces,
CRLF and comments; it selects the first version on a line and rejects entries
without a version. `mkElixir` now takes `pkgs: beamPkgs: version: hash`, matching
the upstream source override API.

The default Nixpkgs input tracks stable `nixos-26.05`. Its legacy extensible
BEAM sets use `packagesWith` and `extend`; newer Nixpkgs inputs use
`overrideScope`, including releases where `packagesWith` has been removed.
Both paths bind Elixir to the requested OTP rather than the Nixpkgs default.

Compatibility bounds follow the
[stable Elixir 1.20.4 table](https://github.com/elixir-lang/elixir/blob/v1.20.4/lib/elixir/pages/references/compatibility-and-deprecations.md):
Elixir 1.20 supports OTP 27–29, 1.19 supports 26–28, 1.17/1.18 support 25–27,
and 1.15/1.16 support 24–26. Patch-level compatibility additions in older
releases are also respected. New Elixir minor releases require a reviewed bound.

Cache publishing only runs on `develop` when an existing cache is explicitly
configured via `CACHIX_CACHE_NAME` and `CACHIX_AUTH_TOKEN` credentials are present.
It adds no substituter or trusted key. There is no claim that the approved pair
is available from a binary cache. PR checks do not publish. Livebook and Phoenix
application builds remain outside this bounded BEAM check matrix.

On Darwin with an older build shell, custom BEAM builds use the pinned Bash
5.3p20 package in `lib/buildStdenv.nix`. GNU patch 016 fixes a macOS dynamic-pipe
heredoc deadlock reproducible under load. The workaround changes only these
builds' stdenv and leaves dependency toolchains and consumers' package sets alone.
A configure wrapper also runs cached wxWidgets' `wx-config` with that shell,
retaining the base builder's selected wxWidgets libraries. The generated BEAM
script shebangs also use this noninteractive shell. Newer
build shells use the caller's stdenv directly.

The optional Erlang language-server setting uses ELP when available. Stable
Nixpkgs' prebuilt ELP supports OTP 28 but not OTP 29; unsupported requests fail
with a diagnostic rather than silently using another OTP.
`devshell-interface` checks shell and editor derivation evaluation; it does not
build or exercise editor servers.
