{lib}: path: let
  # asdf permits leading whitespace, tabs, CRLF and inline comments. Select
  # the first version when several are listed, as the original shim did.
  tokens = line:
    builtins.filter (x: builtins.isString x && x != "")
    (builtins.split "[[:space:]]+" (builtins.head (lib.splitString "#" line)));
  rows =
    builtins.filter (row: row != [])
    (map tokens (lib.splitString "\n" (builtins.readFile path)));
  pair = row:
    if builtins.length row < 2
    then throw "beam-flakes: .tool-versions entry '${builtins.head row}' has no version"
    else lib.nameValuePair (builtins.head row) (builtins.elemAt row 1);
in
  builtins.listToAttrs (map pair rows)
