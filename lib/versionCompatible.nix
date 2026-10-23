{
  lib,
  normalizeElixir,
}: elixir: erlang: let
  # Stable Elixir 1.20.4 compatibility table, including patch-level additions:
  # https://github.com/elixir-lang/elixir/blob/v1.20.4/lib/elixir/pages/references/compatibility-and-deprecations.md
  # Each row is [inclusive Elixir minimum, exclusive maximum, OTP min, OTP max].
  bounds = [
    ["1.20.0" "1.21.0" "27" "30"]
    ["1.19.0" "1.20.0" "26" "29"]
    ["1.17.0" "1.19.0" "25" "28"]
    ["1.15.0" "1.17.0" "24" "27"]
    ["1.14.5" "1.15.0" "23" "27"]
    ["1.14.0" "1.14.5" "23" "26"]
    ["1.13.4" "1.14.0" "22" "26"]
    ["1.12.0" "1.13.4" "22" "25"]
    ["1.11.4" "1.12.0" "21" "25"]
    ["1.11.0" "1.11.4" "21" "24"]
    ["1.10.3" "1.11.0" "21" "24"]
    ["1.10.0" "1.10.3" "21" "23"]
    ["1.8.0" "1.10.0" "20" "23"]
    ["1.7.0" "1.8.0" "19" "23"]
    ["1.6.6" "1.7.0" "19" "22"]
    ["1.6.0" "1.6.6" "19" "21"]
    ["1.5.0" "1.6.0" "18" "21"]
    ["1.4.5" "1.5.0" "18" "21"]
    ["1.3.0" "1.4.5" "18" "20"]
    ["1.2.6" "1.3.0" "18" "20"]
    ["1.2.0" "1.2.6" "18" "19"]
    ["1.1.0" "1.2.0" "17" "19"]
    ["1.0.5" "1.1.0" "17" "19"]
    ["1.0.0" "1.0.5" "17" "18"]
  ];
  el = normalizeElixir elixir;
  # Compare OTP majors; patch/minor releases stay within each documented major.
  otp = lib.versions.major erlang;
  at = builtins.elemAt;
in
  builtins.any (
    b:
      lib.versionAtLeast el (at b 0)
      && lib.versionOlder el (at b 1)
      && lib.versionAtLeast otp (at b 2)
      && lib.versionOlder otp (at b 3)
  )
  bounds
