{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake.lib) expand;
  inherit (flake) config;

  dbDir = "${expand config.dataDir}/mysql";
  dbSocket = expand config.mysql.socket;

  # Preset flags for mysql server
  mysqld = toString [
    "${pkgs.mysql80}/bin/mysqld"
    "--user=$USER"
    "--socket=${dbSocket}"
    "--datadir=${dbDir}"
    "--mysqlx=0"
    "--default-authentication-plugin=mysql_native_password"
    "--binlog_expire_logs_seconds=259200"
  ];

  # Used after initialization to update root password to "x" and create regular user
  mysql = toString [
    "${pkgs.mysql80}/bin/mysql"
    "--user=root"
    "--socket=${dbSocket}"
    "--connect-expired-password"
  ];

  # Used to shut down temporary server after initializing
  mysqladmin = toString [
    "${pkgs.mysql80}/bin/mysqladmin"
    "--user=root"
    "--socket=${dbSocket}"
    "--password=${config.mysql.password}"
  ];

  dbLog = "${expand config.dataDir}/mysql-init.log";
  dbInit = with config.mysql; pkgs.writeText "init.sql" ''
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${password}';
    CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${password}';
    CREATE USER IF NOT EXISTS '${username}'@'localhost' IDENTIFIED BY '${password}';
    CREATE USER IF NOT EXISTS '${username}'@'%' IDENTIFIED BY '${password}';
    CREATE DATABASE IF NOT EXISTS ${username};
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
    GRANT ALL PRIVILEGES ON *.* TO '${username}'@'%';
    FLUSH PRIVILEGES;
  '';

  grep = "${pkgs.gnugrep}/bin/grep";
  sleep = "${pkgs.coreutils}/bin/sleep";

# Wrapper for mysqld to automate initialization if needed
in pkgs.writeScriptBin "mysqld" ''
  #!/usr/bin/env bash

  # Check if datadir exists
  if [ ! -d "${dbDir}" ]; then

    # If missing, create ensure init log is empty
    mkdir -p ${dbDir}
    rm -f ${dbLog}

    # Initialize mysql and save temp password to variable
    ${mysqld} --initialize --log-error=${dbLog} 
    PASS=$(${grep} 'temporary password' "${dbLog}" | awk '{print $NF}')

    # Start mysql, update root password and create regular user, shutdown again
    ${mysqld} --skip-networking &
    ${sleep} 5
    ${mysql} --password="$PASS" < ${dbInit}
    ${mysqladmin} shutdown
  fi

  # Run mysql server
  exec ${mysqld} "''${@}" 
''
