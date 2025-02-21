{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake.lib) expand;
  inherit (flake) config;

  mysql = toString [
    "${pkgs.mysql80}/bin/mysql"
    "--host=localhost"
    "--socket=${expand config.mysql.socket}"
    "--user=root"
    "--password=${config.mysql.password}"
  ];

in pkgs.writeScriptBin "mysql" ''
  #!/usr/bin/env bash
  exec ${mysql} ''${@} 
''
