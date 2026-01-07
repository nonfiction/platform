{
  flake,
  pkgs,
  ...
}:
pkgs.writeScriptBin "hostname"
# bash
''
  #!/usr/bin/env bash
  echo "${flake.config.domain}"
''
