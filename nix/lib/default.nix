{ flake, inputs, ... }: let 

  inherit (builtins) replaceStrings toString;
  inherit (inputs.nixpkgs) lib;
  inherit (lib) getExe mapAttrsToList;

in rec {

  # Template for flake configuration
  mkConfig = name: rec {
    inherit name; # project name
    domain = "local.nfweb.ca"; # base domain
    host = "${name}.${domain}"; 
    wp.uploadsDir = "${dataDir}/uploads/${name}"; # wp uploads
    wp.port = mkPort name; # published port
    mysql.socket = "${dataDir}/mysql.sock"; # alternative to port
    mysql.username = "nonfiction"; # additional db user
    mysql.password = "x"; # simple password for localhost
    mysql.dump = "${dataDir}/${name}.sql"; # database dumps
    mysql.database = replaceStrings [ "." ] [ "_" ] host;
    adminer.port = 8885; # database manager
    traefik.port = 8886; # traefik dashboard
    traefik.http.port = 8887; # redirects to https
    traefik.https.port = 8888; # https reverse proxy
    traefik.email = "dns@nonfiction.ca"; # acme
    dataDir = "~/.local/share/platform"; # base directory
  };

  # Base list of environment variables for devshell, plus extra
  mkEnv = config: extra: 
    let env = rec {
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
    } // extra; 
  in mapAttrsToList (name: value: { inherit name value; }) env;

  # Resolve tilde to $HOME 
  expand = str: replaceStrings ["~"] ["$HOME"] str;

  # Merge platform packages with pkgs
  mkPkgs = perSystem: 
    perSystem.nixpkgs // { platform = perSystem.platform or perSystem.self; };

  # Base list of packages for devshell, plus extra
  mkPackages = pkgs: extra: [
    pkgs.docker-compose
    pkgs.doctl
    pkgs.gh
    pkgs.gnumake
    pkgs.nodePackages.nodejs
    # pkgs.nodePackages.webpack-cli
    pkgs.php82Packages.composer
    pkgs.platform.mysql
    pkgs.platform.mysqldump
    pkgs.platform.nf
    pkgs.process-compose
  ] ++ extra;

  # Deterministic port number from string
  mkPort = str: let
    hash = builtins.hashString "sha256" str;
    firstChar = builtins.substring 0 1 hash;
    baseNum = builtins.stringLength (builtins.head (builtins.split firstChar "abcdef0123456789"));
    hashNum = baseNum * (builtins.stringLength hash);
    portRange = 65535 - 49152;
  in 49152 + (hashNum - (portRange * (hashNum / portRange)));

  # devshell.startup.platform = flake.lib.startup pkgs config;
  startup = pkgs: config: let
    yaml = pkgs.writeTextFile {
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
    text = ''
      mkdir -p ${expand config.dataDir} ${expand config.wp.uploadsDir}
      ln -sf ${yaml} ./process-compose.yaml
      process-compose -D > /dev/null 2>&1 & disown
      echo ready
    '';
  in { inherit text; };

  # Generate db init sql to create new user/database
  dbInit = pkgs: config: let  
    user = config.name; 
    admin = config.mysql.username; 
    inherit (config.mysql) password database;
  in pkgs.writeText "init.sql" ''
    SET @row_count = (SELECT COUNT(*) FROM mysql.user WHERE user='${user}' AND host='%';);
    IF @row_count < 1 THEN
      CREATE USER '${user}'@'%' IDENTIFIED WITH mysql_native_password BY '${password}';
    END IF;
    CREATE DATABASE IF NOT EXISTS ${database} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
    GRANT ALL ON ${database}.* TO '${user}'@'%';
    GRANT ALL ON ${database}.* TO '${admin}'@'%';
  '';

}
