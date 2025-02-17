{ pkgs, ... }: let

  dataDir = "$HOME/.local/share/platform";

  adminer = builtins.toString [
    "${pkgs.php}/bin/php"
    "-S 0.0.0.0:8885"
    "${pkgs.adminer-pematon}/index.php"
  ];

in pkgs.writeScriptBin "adminer" ''
  #!/usr/bin/env bash
  mkdir -p ${dataDir}/traefik
  cp -f ${./adminer.yml} ${dataDir}/traefik/adminer.yml
  exec ${adminer} 
''
