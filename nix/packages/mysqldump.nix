{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake.lib) expand;
  cfg = flake.config;

  mysqldump = toString [
    "${pkgs.mysql80}/bin/mysqldump"
    "--host=localhost"
    "--socket=${expand cfg.mysql.socket}"
    "--user=root"
    "--password=${cfg.mysql.password}"
  ];

in pkgs.writeScriptBin "mysqldump" ''
  #!/usr/bin/env bash
  exec ${mysqldump} "''${@}" 
''
