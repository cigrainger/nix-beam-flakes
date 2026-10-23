# Credits

I would not have pushed this very far were it not for flakes and
[flake-parts](https://github.com/hercules-ci/flake-parts). I've gotten several
rounds of useful feedback directly from discussions on the `flake-parts`
repository as well as learned a lot from studying its code.

I also take some inspiration from
[`oxalica/rust-overlay`](https://github.com/oxalica/rust-overlay).

This fork incorporates BEAM scope overrides, source overrides, language-server
compatibility, and release checksums from
[elixir-tools/nix-beam-flakes at 949f26e7ad5a85e29d4e0d79649c82b0f399562f](https://github.com/elixir-tools/nix-beam-flakes/commit/949f26e7ad5a85e29d4e0d79649c82b0f399562f).
The imported paths are `lib/default.nix`, `data/elixir.json`, and
`data/erlang.json`. Fork modifications correct version metadata, normalize direct
helper inputs, handle removed builders, and add regression/runtime checks.
The upstream Apache-2.0 license is preserved in `LICENSE`; existing documentation
and this fork's `develop` default remain in place.

The added Elixir 1.20.4 and OTP 29.1.2 source hashes are taken from the official
Nixpkgs [Elixir definition](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/development/interpreters/elixir/1.20.nix)
and [OTP definition](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/interpreters/erlang/29.nix).
