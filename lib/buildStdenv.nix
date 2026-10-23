{
  lib,
  pkgs,
}:
# Bash 5.3 before patch 016 can hang on configure heredocs when macOS shrinks
# pipe capacity under load. Keep the workaround local to source BEAM builds;
# dependencies and the consumer's package set retain their original stdenv.
# https://ftp.gnu.org/gnu/bash/bash-5.3-patches/bash53-016
if pkgs.stdenv.buildPlatform.isDarwin && lib.versionOlder pkgs.bash.version "5.3p16"
then let
  source = builtins.fetchTree {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "5adc50831c259f87faeb09ddf930d43597197473";
    narHash = "sha256-Q/8KLB6jNfpaUN1HAedE/u/Et9feE/zYSsutBLKrCFk=";
  };
  shell =
    (import source {
      system = pkgs.stdenv.buildPlatform.system;
      config = {};
      overlays = [];
    }).bashNonInteractive;
in
  pkgs.stdenv.override {
    # This package-local adapter intentionally adds the pinned shell closure.
    allowedRequisites = null;
    shell = "${shell}/bin/bash";
    initialPath = [shell] ++ pkgs.stdenv.initialPath;
  }
else pkgs.stdenv
