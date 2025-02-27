{ lib, ... }: let
  inherit (lib) getExe mapAttrsToList;

# Standard devshell for all platform projects
in flake: perSystem: extra: let

  # This system's flake config and lib
  inherit (flake) config;
  inherit (flake.lib) expand;

  # Merge platform packages with pkgs
  pkgs = perSystem.nixpkgs // { platform = perSystem.platform or perSystem.self; };

  # List of secrets to merge with env
  secrets = map (name: { 
    inherit name; eval = "$(cat ${config.dataDir}/secrets/${name} 2>/dev/null)"; 
  }) config.secrets;

  # Convert config values to base list of environment variables
  env = rec {
    NAME = config.name; # project/image name
    HOST = config.host; # project url
    DB_DUMP = config.mysql.dump;
    DB_HOST = "localhost:/run/mysqld/mysqld.sock"; # bind mount, container
    DB_SOCKET = config.mysql.socket; # bind mount, host
    DB_NAME = config.mysql.database;
    DB_PASSWORD = config.mysql.password;
    DB_USER = config.name;
    DOCKER_REGISTRY = config.domain;
    MAKEFLAGS = "-f Makefile.local";
    WP_ENV = "development";
    WP_PORT = config.wp.port;
    WP_UPLOADS_DIR = config.wp.uploadsDir;
    PC_PORT_NUM = 8889; # process-compose api port
  } // (extra.env or {}); 

  # Create process-compose.yaml for running platform stack
  process-compose = pkgs.writeTextFile {
    name = "process-compose.yaml";
    text = builtins.toJSON {
      processes.mysqld = {
        command = getExe pkgs.platform.mysqld;
        description = "MySQL daemon";
      };
      processes.adminer = {
        command = getExe pkgs.platform.adminer;
        description = "Adminer MySQL web frontend";
      };
      processes.traefik = {
        command = getExe pkgs.platform.traefik;
        description = "Traefik reverse proxy";
      };
    };
  };

  init.sql = with config; pkgs.writeText "init.sql" ''
    SET @row_count = (SELECT COUNT(*) FROM mysql.user WHERE user='${name}' AND host='%';);
    IF @row_count < 1 THEN
      CREATE USER '${name}'@'%' IDENTIFIED WITH mysql_native_password BY '${mysql.password}';
    END IF;
    CREATE DATABASE IF NOT EXISTS ${mysql.database} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
    GRANT ALL ON ${mysql.database}.* TO '${name}'@'%';
    GRANT ALL ON ${mysql.database}.* TO '${mysql.username}'@'%';
  '';

  # init.db = pkgs.writeScriptBin "mysql" ''
  #   #!/usr/bin/env bash
  #   mysql < ${init.sql}
  # '';

in perSystem.devshell.mkShell {

  # Set name of devshell from config
  devshell.name = config.name;

  # Startup script of devshell, plus extra
  devshell.startup.platform.text = ''
    ln -sf ${process-compose} ./process-compose.yaml
    mkdir -p ${expand config.dataDir} ${expand config.wp.uploadsDir}
    [[ -d ${expand config.dataDir}/secrets ]] || secrets
    ${extra.startup or ""}
  ''; 

  # Base list of environment variables for devshell, plus secrets and extra
  env = secrets ++ (mapAttrsToList (name: value: { inherit name value; }) env);

  # Base list of commands for devshell, plus extra
  commands = [{
    name = "secrets";
    help = "edit platform secrets";
    package = pkgs.platform.secrets;
  } {
    name = "platform";
    help = "launch platform and attach";
    command = "process-compose -D && process-compose attach";
  } {
    category = "docker";
    name = "init";
    help = "setup database & install dependencies";
    command = ''
      mysql < ${init.sql}
      npm update --save-dev
      compose update && composer dump-autoload -o
    '';
  } {
    category = "docker";
    name = "build";
    help = "build container";
    command = "docker compose build";
  } {
    category = "docker";
    name = "up";
    help = "run container";
    command = "docker compose up -d";
  } {
    category = "docker";
    name = "logs";
    help = "container logs";
    command = "docker compose logs -f";
  }] ++ (extra.commands or []);

  # Base list of packages for devshell, plus extra
  packages = [
    pkgs.docker-compose
    pkgs.doctl
    pkgs.gh
    pkgs.git
    pkgs.gnumake
    pkgs.lazydocker
    pkgs.lazygit
    pkgs.nodePackages.nodejs
    # pkgs.nodePackages.webpack-cli
    pkgs.php82Packages.composer
    pkgs.platform.hostname
    pkgs.platform.mysql
    pkgs.platform.mysqldump
    pkgs.platform.nf
    pkgs.platform.secrets
    pkgs.process-compose
    pkgs.smenu
  ] ++ (extra.packages or []);

}
