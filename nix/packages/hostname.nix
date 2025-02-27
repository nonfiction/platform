{ flake, pkgs, ... }: pkgs.writeScriptBin "hostname" ''
  #!/usr/bin/env bash
  echo "${flake.config.domain}"
''
