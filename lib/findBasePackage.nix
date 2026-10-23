_: let
  inherit (builtins) elemAt splitVersion;
in {
  elixirBasePackage = beamPkgs: version: let
    split = splitVersion version;
    major = elemAt split 0;
    minor = elemAt split 1;
  in let
    candidate = builtins.tryEval (beamPkgs."elixir_${major}_${minor}" or null);
  in
    if candidate.success
    then candidate.value
    else null;

  otpBasePackage = pkgs: version: let
    inherit (pkgs.beam) interpreters;
    major = elemAt (splitVersion version) 0;
  in
    # EOL builders can remain as throwing aliases in consumer inputs.
    let
      candidate = builtins.tryEval (interpreters."erlang_${major}" or null);
    in
      if candidate.success
      then candidate.value
      else null;
}
