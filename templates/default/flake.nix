{
  description = "My Elixir application";

  inputs = {
    beam-flakes = {
      url = "github:cigrainger/nix-beam-flakes/develop";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = inputs @ {
    beam-flakes,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [beam-flakes.flakeModule];

      systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"];

      perSystem = _: {
        beamWorkspace = {
          enable = true;
          devShell = {
            languageServers.elixir = true;
            languageServers.erlang = false;
          };
          versions = {
            elixir = "1.20.1";
            erlang = "29.0.2";
          };
        };
      };
    };
}
