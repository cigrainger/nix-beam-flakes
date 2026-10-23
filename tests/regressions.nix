{
  lib,
  beamLib,
  pkgs,
  checkDerivations ? true,
}: let
  check = name: condition: assert lib.assertMsg condition "beam-flakes regression: ${name}"; true;
  parsed = beamLib.parseToolVersions ./fixtures/approved.tool-versions;
  bases = import ../lib/findBasePackage.nix {inherit lib;};
  compatible = beamLib.versionCompatible;
  missingPkgs.beam.interpreters = {
    erlang_26 = throw "removed OTP alias";
  };
  cases = [
    ["1.20.4" "26.2" false]
    ["1.20.4" "27.0" true]
    ["1.20.1-otp-29" "29.0.2" true]
    ["1.20.4" "30.0" false]
    ["1.19.5" "25.3" false]
    ["1.19.5" "26.0" true]
    ["1.19.5" "28.5" true]
    ["1.19.5" "29.0" false]
    ["1.18.4" "24.3" false]
    ["1.18.4" "25.0" true]
    ["1.18.4" "27.3" true]
    ["1.18.4" "28.0" false]
    ["1.17.3" "27.3" true]
    ["1.16.3" "27.0" false]
    ["1.14.4" "26.0" false]
    ["1.14.5" "26.0" true]
    ["1.13.3" "25.0" false]
    ["1.13.4" "25.0" true]
    ["1.11.3" "24.0" false]
    ["1.11.4" "24.0" true]
    ["1.2.5" "19.0" false]
    ["1.2.6" "19.0" true]
    ["1.21.0" "29.0" false]
  ];
  pair = beamLib.packageSetFromToolVersions pkgs ./fixtures/approved.tool-versions {};
  scope = beamLib.beamPackagesFor pkgs "29.0.2" pair.erlang;
  modernScope = beamLib.beamPackagesFor {
    beam = {
      packages.erlang_29.overrideScope = extension: extension {} {};
      packagesWith = throw "modern inputs must not touch removed packagesWith";
    };
  } "29.0.2" {version = "29.0.2";};
  stableScope = beamLib.beamPackagesFor {
    beam = {
      packages.erlang_29 = {};
      packagesWith = erlang: {inherit erlang;};
    };
  } "29.0.2" {version = "29.0.2";};
in
  builtins.deepSeq [
    (check "whitespace/comments/CRLF" (parsed
      == {
        elixir = "1.20.1-otp-29";
        erlang = "29.0.2";
      }))
    (check "malformed line" (!(builtins.tryEval (builtins.deepSeq (beamLib.parseToolVersions ./fixtures/invalid.tool-versions) true)).success))
    (check "normalization" (beamLib.normalizeElixir "1.20.1-otp-29" == "1.20.1"))
    (check "compatibility boundaries" (builtins.all (row: compatible (builtins.elemAt row 0) (builtins.elemAt row 1) == builtins.elemAt row 2) cases))
    (check "missing OTP builder" (bases.otpBasePackage missingPkgs "25.3" == null))
    (check "throwing OTP alias" (bases.otpBasePackage missingPkgs "26.2" == null))
    (check "enumeration skips missing/removed builders" (beamLib.compatibleVersionPackages missingPkgs == {}))
    (check "modern scope API" (modernScope.erlang.version == "29.0.2"))
    (check "26.05 scope API" (stableScope.erlang.version == "29.0.2"))
    (check "Elixir metadata" (pair.elixir.version == "1.20.1"))
    (check "OTP metadata" (pair.erlang.version == "29.0.2"))
    (check "Elixir source" (pair.elixir.src.tag == "v1.20.1"))
    (check "OTP source" (pair.erlang.src.tag == "OTP-29.0.2"))
    (check "Elixir builds against requested OTP" (builtins.any (dep: (dep.pname or "") == "erlang" && dep.version == "29.0.2") pair.elixir.buildInputs))
    (check "scope uses requested OTP" (scope.erlang.version == "29.0.2"))
    (check "direct helper accepts asdf suffix" ((beamLib.mkPackageSet {
        inherit pkgs;
        elixirVersion = "1.20.1-otp-29";
        erlangVersion = "29.0.2";
      }).elixir.version
      == "1.20.1"))
    (check "available packages enumerate" ((beamLib.compatibleVersionPackages pkgs)."erlang_29.0.2".elixirs."elixir_1.20.1".version == "1.20.1"))
    (check "scope derivation" (!checkDerivations || scope.erlang.drvPath == pair.erlang.drvPath))
    (check "direct helper derivation" (!checkDerivations
      || (beamLib.mkPackageSet {
        inherit pkgs;
        elixirVersion = "1.20.1-otp-29";
        erlangVersion = "29.0.2";
      }).elixir.drvPath
      == pair.elixir.drvPath))
  ]
  true
