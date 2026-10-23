{
  description = "Nix-based BEAM toolchain management";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [./parts/all-parts.nix ./local-parts];
      systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
      };

      flake = {
        flakeModule = ./parts/all-parts.nix;

        templates = {
          default = {
            path = ./templates/default;
            description = "An environment suitable for developing Elixir applications";
          };

          phoenix = {
            path = ./templates/phoenix;
            description = "An environment suitable for developing Phoenix applications";
          };
        };
      };
    };
}
