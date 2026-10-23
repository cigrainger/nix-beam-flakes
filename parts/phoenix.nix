{
  config,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkMerge
    mkIf
    ;
  inherit
    (flake-parts-lib)
    mkPerSystemOption
    mkSubmoduleOptions
    ;
in {
  options = {
    perSystem = mkPerSystemOption (_: {
      _file = ./phoenix.nix;

      options.beamWorkspace.devShell = mkSubmoduleOptions {
        phoenix = mkEnableOption "phoenix framework";
      };
    });
  };

  config = {
    perSystem = {
      config,
      pkgs,
      ...
    }: {
      beamWorkspace.devShell.packages = mkMerge [
        # Darwin frameworks come from stdenv's SDK; legacy apple_sdk was removed.
        (mkIf (config.beamWorkspace.devShell.phoenix && pkgs.stdenv.isLinux) [pkgs.inotify-tools])
      ];
    };
  };
}
