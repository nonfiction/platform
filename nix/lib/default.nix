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
    secrets = [ "DO_AUTH_TOKEN" ]; # list of secret env variables
  };

  # Base list of environment variables for devshell, plus extra
  mkEnv = cfg: pkgs: extra: let 

    secrets = map (name: { 
      inherit name; eval = "$(cat ${cfg.dataDir}/secrets/${name} 2>/dev/null)"; 
    }) cfg.secrets;

    env = rec {
      NAME = cfg.name; # project/image name
      HOST = cfg.host; # project url
      DB_DUMP = cfg.mysql.dump;
      DB_HOST = "localhost:/run/mysqld/mysqld.sock"; # bind mount, container
      DB_SOCKET = cfg.mysql.socket; # bind mount, host
      DB_NAME = cfg.mysql.database;
      DB_PASSWORD = cfg.mysql.password;
      DB_USER = cfg.name;
      DOCKER_REGISTRY = cfg.domain;
      MAKEFLAGS = "-f Makefile.local";
      WP_ENV = "development";
      WP_PORT = cfg.wp.port;
      WP_UPLOADS_DIR = cfg.wp.uploadsDir;
      PC_PORT_NUM = 8889; # process-compose api port
    } // extra; 

  in secrets ++ (mapAttrsToList (name: value: { inherit name value; }) env);

  # Resolve tilde to $HOME 
  expand = str: replaceStrings ["~"] ["$HOME"] str;

  # Merge platform packages with pkgs
  mkPkgs = perSystem: 
    perSystem.nixpkgs // { platform = perSystem.platform or perSystem.self; };

  # Base list of packages for devshell, plus extra
  mkPackages = cfg: pkgs: extra: [
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
    pkgs.platform.mysql
    pkgs.platform.mysqldump
    pkgs.platform.nf
    pkgs.platform.secrets
    pkgs.process-compose
    pkgs.smenu
  ] ++ extra;

  # Base list of commands for devshell, plus extra
  mkCommands = cfg: pkgs: extra: [{
    name = "secrets";
    help = "edit platform secrets";
    package = pkgs.platform.secrets;
  } {
  # mkCommands = cfg: pkgs: extra: [{
    name = "platform";
    help = "launch platform and attach";
    command = "process-compose -D && process-compose attach";
  }] ++ extra;

  # Deterministic port number from string
  mkPort = str: let
    hash = builtins.hashString "sha256" str;
    firstChar = builtins.substring 0 1 hash;
    baseNum = builtins.stringLength (builtins.head (builtins.split firstChar "abcdef0123456789"));
    hashNum = baseNum * (builtins.stringLength hash);
    portRange = 65535 - 49152;
  in 49152 + (hashNum - (portRange * (hashNum / portRange)));

  # devshell.startup.platform = flake.lib.startup pkgs cfg;
  startup = cfg: pkgs: let
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
      ln -sf ${yaml} ./process-compose.yaml
      mkdir -p ${expand cfg.dataDir} ${expand cfg.wp.uploadsDir}
      [[ -d ${expand cfg.dataDir}/secrets ]] || secrets
    '';
  in { inherit text; };

  # Generate db init sql to create new user/database
  dbInit = cfg: pkgs: let  
    user = cfg.name; 
    admin = cfg.mysql.username; 
    inherit (cfg.mysql) password database;
  in pkgs.writeText "init.sql" ''
    SET @row_count = (SELECT COUNT(*) FROM mysql.user WHERE user='${user}' AND host='%';);
    IF @row_count < 1 THEN
      CREATE USER '${user}'@'%' IDENTIFIED WITH mysql_native_password BY '${password}';
    END IF;
    CREATE DATABASE IF NOT EXISTS ${database} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
    GRANT ALL ON ${database}.* TO '${user}'@'%';
    GRANT ALL ON ${database}.* TO '${admin}'@'%';
  '';

  # Bash script helpers
  helpers = ./helpers.sh;

}
