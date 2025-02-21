{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake.lib) expand;
  inherit (flake) config;

  mysqldump = toString [
    "${pkgs.mysql80}/bin/mysqldump"
    "--host=localhost"
    "--socket=${expand config.mysql.socket}"
    "--user=root"
    "--password=${config.mysql.password}"
  ];

in pkgs.writeScriptBin "mysqldump" ''
  #!/usr/bin/env bash
  exec ${mysqldump} "''${@}" 
''
