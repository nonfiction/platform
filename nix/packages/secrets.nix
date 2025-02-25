{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake.lib) expand helpers;
  cfg = flake.config;
  secrets = "${expand cfg.dataDir}/secrets";

in pkgs.writeScriptBin "secrets" ''
  #!/usr/bin/env bash
  source ${helpers}
  mkdir -p ${secrets}
  for name in ${toString cfg.secrets}; do
    info $name
    prev="$(touch ${secrets}/$name && cat ${secrets}/$name)"
    next="$(ask - "$prev")"
    echo $next > ${secrets}/$name
  done
''
