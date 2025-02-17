{ pkgs, ... }: let
  mysqldump = builtins.toString [
    "${pkgs.mysql80}/bin/mysqldump"
    "--host=127.0.0.1"
    "--port=25060"
    "--user=root"
    "--password=x"
    "--protocol=tcp"
  ];
in pkgs.writeScriptBin "mysqldump" ''
  #!/usr/bin/env bash
  exec ${mysqldump} ''${@} 
''
