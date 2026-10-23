# Adapted from elixir-tools/nix-beam-flakes 949f26e (Apache-2.0).
# Fork changes: exact version metadata, safe enumeration and normalized helpers.
{lib}: let
  inherit (builtins) concatStringsSep mapAttrs splitVersion;
  inherit (lib) take;
  inherit (lib.attrsets) filterAttrs mapAttrs' nameValuePair;
  inherit (lib.trivial) importJSON pipe;
  inherit (findBasePackage) elixirBasePackage otpBasePackage;

  compatibleVersions = let
    elixirsFor = erlangVersion:
      pipe versions.elixir [
        (filterAttrs (n: _v: versionCompatible n erlangVersion))
        (mapAttrs (version: checksum: {inherit version checksum;}))
      ];
    genCompatiblePkgSet = version: checksum:
      nameValuePair version {
        erlang = {inherit version checksum;};
        elixirs = elixirsFor version;
      };
  in
    mapAttrs' genCompatiblePkgSet versions.erlang;

  compatibleVersionPackages = pkgs: let
    expandElixir = erlangVersion: erlang: _name: attrs:
      if erlang != null
      then
        nameValuePair "elixir_${attrs.version}" (
          mkElixir pkgs (beamPackagesFor pkgs erlangVersion erlang) attrs.version attrs.checksum
        )
      else null;
    expandErlang = _erlangVersion: checksumSet: let
      erlang = mkErlang pkgs checksumSet.erlang.version checksumSet.erlang.checksum;
      elixirs = pipe checksumSet.elixirs [
        (mapAttrs' (expandElixir checksumSet.erlang.version erlang))
        (filterAttrs (_n: v: v != null))
      ];
    in
      nameValuePair "erlang_${erlang.version}" {inherit erlang elixirs;};
  in
    pipe compatibleVersions [
      (filterAttrs (erlangVersion: _attrs: erlangExists pkgs erlangVersion))
      (mapAttrs' expandErlang)
    ];

  erlangExists = pkgs: version: otpBasePackage pkgs version != null;

  beamPackagesFor = pkgs: erlangVersion: erlang: let
    scope = pkgs.beam.packages."erlang_${lib.versions.major erlangVersion}";
  in
    if scope ? overrideScope
    then scope.overrideScope (_: _: {inherit erlang;})
    # Nixpkgs 26.05's extensible set captures erlang in package arguments, so
    # extending only its erlang attribute would leave Elixir on the base OTP.
    else pkgs.beam.packagesWith erlang;

  overrideBeamScope = scope: extension:
    if scope ? overrideScope
    then scope.overrideScope extension
    else scope.extend extension;

  findBasePackage = import ./findBasePackage.nix {inherit lib;};

  buildStdenv = pkgs: import ./buildStdenv.nix {inherit lib pkgs;};

  latestVersions = import ./latestVersions.nix {inherit lib versions;};

  mkElixir = pkgs: beamPkgs: version: hash: let
    basePkg = elixirBasePackage beamPkgs version;
  in
    if basePkg != null
    then
      (basePkg.override {stdenv = buildStdenv pkgs;}).overrideAttrs {
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "elixir-lang";
          repo = "elixir";
          tag = "v${version}";
          inherit hash;
        };
      }
    else null;

  mkErlang = pkgs: version: hash: let
    basePkg = otpBasePackage pkgs version;
  in
    if basePkg != null
    then
      (basePkg.override {stdenv = buildStdenv pkgs;}).overrideAttrs {
        inherit version;

        src = pkgs.fetchFromGitHub {
          owner = "erlang";
          repo = "otp";
          tag = "OTP-${version}";
          inherit hash;
        };
      }
    else null;

  mkPackageSet = {
    elixirVersion,
    erlangVersion,
    elixirLanguageServer ? false,
    erlangLanguageServer ? false,
    # Upstream Rebar project is presumed to have done its own CI diligence WRT Erlang versions
    rebarCheck ? false,
    pkgs,
  }: let
    normalizedElixir = normalizeElixir elixirVersion;
    erlang = mkErlang pkgs erlangVersion versions.erlang.${erlangVersion};
    beamPkgs = overrideBeamScope (beamPackagesFor pkgs erlangVersion erlang) (
      final: _: {
        elixir = mkElixir pkgs final normalizedElixir versions.elixir.${normalizedElixir};
      }
    );
    inherit (beamPkgs) elixir;
  in
    assert lib.assertMsg (erlang != null) "beam-flakes: no OTP builder for ${erlangVersion} in this nixpkgs";
    assert lib.assertMsg (elixir != null) "beam-flakes: no Elixir builder for ${normalizedElixir} in this nixpkgs";
    assert lib.assertMsg (versionCompatible normalizedElixir erlangVersion) "beam-flakes: unsupported Elixir ${normalizedElixir}/OTP ${erlangVersion} pairing";
      {
        inherit (beamPkgs) erlang;
        inherit elixir;
      }
      // (
        if elixirLanguageServer
        then {
          elixir-ls = (beamPkgs.elixir-ls.override {inherit elixir;}).overrideAttrs (old: {
            buildPhase =
              # Elixir 1.16.0 or newer
              if ((builtins.compareVersions elixir.version "1.16.0") != -1)
              then ''
                runHook preBuild
                mix do compile --no-deps-check, elixir_ls.release2
                runHook postBuild
              ''
              else old.buildPhase;
          });
        }
        else {}
      )
      // (
        if erlangLanguageServer
        then {
          erlang-ls = let
            candidate =
              if pkgs ? erlang-language-platform
              then pkgs.erlang-language-platform.override {inherit (beamPkgs) erlang;}
              else beamPkgs.erlang-ls;
          in
            if (builtins.tryEval candidate.drvPath).success
            then candidate
            else throw "beam-flakes: this Nixpkgs has no Erlang language server for OTP ${erlangVersion}; disable devShell.languageServers.erlang or select a supported OTP";
        }
        else {}
      )
      // (
        if rebarCheck
        then {}
        else
          lib.genAttrs ["rebar" "rebar3"] (
            p:
              beamPkgs.${p}.overrideAttrs (_old: {
                doCheck = false;
              })
          )
      );

  normalizeElixir = version:
    lib.trivial.pipe version [
      (lib.versions.pad 3)
      splitVersion
      (take 3)
      (map toString)
      (concatStringsSep ".")
    ];

  packageSetFromToolVersions = pkgs: toolVersionsPath: args: let
    asdfVersions = parseToolVersions toolVersionsPath;
  in
    mkPackageSet (
      {
        elixirVersion = normalizeElixir asdfVersions.elixir;
        erlangVersion = asdfVersions.erlang;
        inherit pkgs;
      }
      // args
    );

  parseToolVersions = import ./parseToolVersions.nix {inherit lib;};

  inherit (latestVersions) recentElixirs recentErlangs;

  # idea credit: https://github.com/nix-community/nix-github-actions/blob/bfeb681177b5128d061ebbef7ded30bc21a3f135/default.nix
  recentMatrix =
    pipe
    {
      elixir = recentElixirs;
      erlang = recentErlangs;
      os = [
        "macos-26"
        "ubuntu-latest"
      ];
    }
    [
      lib.attrsets.cartesianProduct
      (builtins.filter (set: versionCompatible set.elixir set.erlang))
      (v: {include = v;})
    ];

  versionCompatible = import ./versionCompatible.nix {inherit lib normalizeElixir;};

  versions = {
    elixir = importJSON ../data/elixir.json;
    erlang = importJSON ../data/erlang.json;
  };
in {
  inherit
    compatibleVersions
    compatibleVersionPackages
    versions
    versionCompatible
    ;
  inherit
    mkElixir
    mkErlang
    beamPackagesFor
    mkPackageSet
    normalizeElixir
    ;
  inherit packageSetFromToolVersions parseToolVersions;
  inherit
    (latestVersions)
    latestElixirMinors
    latestErlangMajors
    recentElixirs
    recentErlangs
    ;
  inherit recentMatrix;
}
