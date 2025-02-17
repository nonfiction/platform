{ pkgs, ... }: let
  mysql = builtins.toString [
    "${pkgs.mysql80}/bin/mysql"
    "--host=127.0.0.1"
    "--port=25060"
    "--user=root"
    "--password=x"
    "--protocol=tcp"
  ];
in pkgs.writeScriptBin "mysql" ''
  #!/usr/bin/env bash
  exec ${mysql} ''${@} 
''
