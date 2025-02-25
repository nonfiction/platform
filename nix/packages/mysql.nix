{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake.lib) expand;
  cfg = flake.config;

  mysql = toString [
    "${pkgs.mysql80}/bin/mysql"
    "--host=localhost"
    "--socket=${expand cfg.mysql.socket}"
    "--user=root"
    "--password=${cfg.mysql.password}"
  ];

in pkgs.writeScriptBin "mysql" ''
  #!/usr/bin/env bash
  exec ${mysql} "''${@}" 
''
