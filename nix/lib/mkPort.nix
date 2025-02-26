{ ... }:  

  # Deterministic port number from string
  str: let
    hash = builtins.hashString "sha256" str;
    firstChar = builtins.substring 0 1 hash;
    baseNum = builtins.stringLength (builtins.head (builtins.split firstChar "abcdef0123456789"));
    hashNum = baseNum * (builtins.stringLength hash);
    portRange = 65535 - 49152;
  in 49152 + (hashNum - (portRange * (hashNum / portRange)))
