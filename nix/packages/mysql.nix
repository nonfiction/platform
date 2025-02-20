{ flake, pkgs, ... }: let
  inherit (flake) config;
  inherit (builtins) toString;
  mysql = toString [
    "${pkgs.mysql80}/bin/mysql"
    "--host=127.0.0.1"
    "--port=${toString config.mysql.port}"
    "--user=root"
    "--password=${toString config.mysql.password}"
    "--protocol=tcp"
  ];
in pkgs.writeScriptBin "mysql" ''
  #!/usr/bin/env bash
  exec ${mysql} ''${@} 
''
