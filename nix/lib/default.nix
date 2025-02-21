{ flake, inputs, ... }: let 

  inherit (builtins) replaceStrings toString;
  inherit (inputs.nixpkgs) lib;
  inherit (lib) getExe mapAttrsToList;

  # Resolve tilde to $HOME 
  expand = str: replaceStrings ["~"] ["$HOME"] str;

  # Template for flake configuration
  mkConfig = name: rec {
    inherit name; # project name
    domain = "local.nfweb.ca"; # base domain
    dataDir = "~/.local/share/platform"; # base directory
    wp.uploadsDir = "${dataDir}/uploads/${name}"; # wp uploads
    wp.port = mkPort name; # published port
    mysql.port = 25060; # matches port used by do
    mysql.socket = "${dataDir}/mysql.sock"; # alternative to port
    mysql.username = "nonfiction"; # additional db user
    mysql.password = "x"; # simple password for localhost
    mysql.dump = "${dataDir}/${name}.sql"; # database dumps
    adminer.port = 8885; # database manager
    traefik.port = 8886; # traefik dashboard
    traefik.http.port = 8887; # redirects to https
    traefik.https.port = 8888; # https reverse proxy
    traefik.email = "dns@nonfiction.ca"; # acme
  };

  # Merge platform packages with pkgs
  mkPkgs = perSystem: 
    perSystem.nixpkgs // { platform = perSystem.platform or perSystem.self; };

  # Base list of environment variables for devshell, plus extra
  mkEnv = config: extra: 
    let env = rec {
      NAME = config.name; 
      DB_DUMP = config.mysql.dump;
      DB_HOST = "localhost:/run/mysqld/mysqld.sock";
      DB_NAME = replaceStrings [ "." ] [ "_" ] HOST;
      DB_PASSWORD = config.mysql.password;
      DB_PORT = toString config.mysql.port;
      DB_SOCKET = config.mysql.socket;
      DB_USER = NAME;
      DOCKER_REGISTRY = config.domain;
      HOST = "${config.name}.${config.domain}"; 
      HOST_PASSWORD = NAME;
      HOST_USER = NAME;
      MAKEFLAGS = "-f Makefile.local";
      WP_ENV = "development";
      WP_PORT = config.wp.port;
      WP_UPLOADS_DIR = config.wp.uploadsDir;
    } // extra; 
  in mapAttrsToList (name: value: { inherit name value; }) env;

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
  ] ++ extra;

  # Base serviceGroup for devshell, plus extra
  mkServices = pkgs: extra: {
    platform.services = {
      mysqld.command = "${getExe pkgs.platform.mysqld}";
      traefik.command = "${getExe pkgs.platform.traefik}";
      adminer.command = "${getExe pkgs.platform.adminer}";
    };
  } // extra;

  # Deterministic port number from string
  mkPort = str: let
    hash = builtins.hashString "sha256" str;
    firstChar = builtins.substring 0 1 hash;
    baseNum = builtins.stringLength (builtins.head (builtins.split firstChar "abcdef0123456789"));
    hashNum = baseNum * (builtins.stringLength hash);
    portRange = 65535 - 49152;
  in 49152 + (hashNum - (portRange * (hashNum / portRange)));

in {
  inherit expand mkConfig mkPkgs mkEnv mkPackages mkServices mkPort;
}
