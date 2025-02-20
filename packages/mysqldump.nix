{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake) config;

  mysqldump = toString [
    "${pkgs.mysql80}/bin/mysqldump"
    "--host=127.0.0.1"
    "--port=${toString config.mysql.port}"
    "--user=root"
    "--password=${config.mysql.password}"
    "--protocol=tcp"
  ];
in pkgs.writeScriptBin "mysqldump" ''
  #!/usr/bin/env bash
  exec ${mysqldump} ''${@} 
''
