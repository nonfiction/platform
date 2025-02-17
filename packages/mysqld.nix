{ pkgs, ... }: let
  dataDir = "$HOME/.local/share/platform";

  # Preset flags for mysql server
  mysqld = builtins.toString [
    "${pkgs.mysql80}/bin/mysqld"
    "--port=25060"
    "--user=$USER"
    "--socket=${dataDir}/mysql.sock"
    "--datadir=${dataDir}/mysql"
    "--mysqlx=0"
    "--default-authentication-plugin=mysql_native_password"
    "--binlog_expire_logs_seconds=259200"
  ];

  # Used after initialization to update root password to "x" and create nonfiction user
  mysql = builtins.toString [
    "${pkgs.mysql80}/bin/mysql"
    "--user=root"
    "--socket=${dataDir}/mysql.sock"
    "--connect-expired-password"
  ];

  # Used to shut down temporary server after initializing
  mysqladmin = builtins.toString [
    "${pkgs.mysql80}/bin/mysqladmin"
    "--user=root"
    "--socket=${dataDir}/mysql.sock"
  ];

  grep = "${pkgs.gnugrep}/bin/grep";
  sleep = "${pkgs.coreutils}/bin/sleep";

# Wrapper for mysqld to automate initialization if needed
in pkgs.writeScriptBin "mysqld" ''
  #!/usr/bin/env bash

  # Check if datadir exists
  if [ ! -d "${dataDir}/mysql" ]; then

    # If missing, create ensure init log is empty
    mkdir -p ${dataDir}/mysql
    rm -f ${dataDir}/mysql-init.log

    # Initialize mysql and save temp password to variable
    ${mysqld} --initialize --log-error=${dataDir}/mysql-init.log 
    PASS=$(${grep} 'temporary password' "${dataDir}/mysql-init.log" | awk '{print $NF}')

    # Start mysql, update root password and create nonfiction user, shutdown again
    ${mysqld} --skip-networking &
    ${sleep} 5
    ${mysql} --password="$PASS" < ${./mysqld.sql}
    ${mysqladmin} --password=x shutdown
  fi

  # Run mysql server
  exec ${mysqld} ''${@} 
''
