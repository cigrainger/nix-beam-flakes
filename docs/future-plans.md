# Future Plans

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
