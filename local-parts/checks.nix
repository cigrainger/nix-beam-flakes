{
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    system,
    lib,
    ...
  }: let
    beamLib = self.lib;
    pair = beamLib.packageSetFromToolVersions pkgs ../tests/fixtures/approved.tool-versions {};
    # Exercise the public module as an independent consumer, without local apps.
    mkConsumer = versions: devShell:
      inputs.flake-parts.lib.mkFlake {inherit inputs;} {
        imports = [../parts/all-parts.nix];
        systems = [system];
        perSystem.beamWorkspace = {
          enable = true;
          flakePackages = true;
          inherit versions devShell;
        };
      };
    consumer = mkConsumer {
      fromToolVersions = ../tests/fixtures/approved.tool-versions;
    } {};
    longPatchConsumer = mkConsumer {
      elixir = "1.20.1";
      erlang = "27.3.4.10";
    } {};
    shellConsumer =
      mkConsumer {
        fromToolVersions = ../tests/fixtures/approved.tool-versions;
      } {
        enable = true;
        languageServers.elixir = true;
        languageServers.erlang = false;
        phoenix = true;
      };
    erlangShellConsumer =
      mkConsumer {
        elixir = "1.20.1";
        erlang = "28.5";
      } {
        enable = true;
        languageServers.erlang = true;
      };
    modulePair = consumer.packages.${system};
    regressions = import ../tests/regressions.nix {inherit lib pkgs beamLib;};
  in {
    checks = {
      regression = assert regressions;
      assert longPatchConsumer.packages.${system}.erlang.version == "27.3.4.10";
      assert modulePair.elixir.drvPath == pair.elixir.drvPath;
      assert modulePair.erlang.drvPath == pair.erlang.drvPath;
        pkgs.runCommand "beam-regressions" {} "touch $out";
      # Force the same optional interfaces used by generated dev shells without
      # compiling an editor server as part of the core runtime regression job.
      devshell-interface = assert builtins.isString shellConsumer.devShells.${system}.default.drvPath;
      assert builtins.isString shellConsumer.packages.${system}.elixir-ls.drvPath;
      assert builtins.isString erlangShellConsumer.packages.${system}.erlang-ls.drvPath;
        pkgs.runCommand "beam-devshell-interface" {} "touch $out";
      approved-runtime =
        pkgs.runCommand "elixir-1.20.1-otp-29.0.2-runtime" {
          nativeBuildInputs = [pair.elixir pair.erlang];
        } ''
          export HOME="$TMPDIR"
          export ELIXIR_ERL_OPTIONS="+fnu"
          elixir --version
          elixir -e '
            "1.20.1" = System.version()
            ~c"29" = :erlang.system_info(:otp_release)
            path = Path.join([List.to_string(:code.root_dir()), "releases", "29", "OTP_VERSION"])
            "29.0.2" = path |> File.read!() |> String.trim()
            {:ok, _} = Code.compile_string("defmodule BeamRevivalSmoke do; def value, do: :ok; end") |> then(fn [_ | _] -> {:ok, :compiled} end)
            :ok = BeamRevivalSmoke.value()
          '
          touch "$out"
        '';
    };
    packages.example = pkgs.linkFarmFromDrvs "approved-beam-pair" [pair.elixir pair.erlang];
  };
}
