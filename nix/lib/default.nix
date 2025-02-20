{ flake, inputs, ... }: let 

  inherit (builtins) replaceStrings toString;
  inherit (inputs.nixpkgs) lib;
  inherit (lib) getExe mapAttrsToList;

  # Template for flake configuration
  mkConfig = name: rec {
    inherit name; # project name
    dataDir = "$HOME/.local/share/platform"; # base directory
    uploadsDir = "${dataDir}/uploads/${name}"; # wp uploads
    domain = "local.nfweb.ca"; # base domain
    docker.port = mkPort name; # published port
    mysql.port = 25060; # matches port used by do
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
      WP_ENV = "development";
      HOST = "${config.name}.${config.domain}"; 
      DB_HOST = "127.0.0.1";
      DB_PORT = toString config.mysql.port;
      DB_NAME = replaceStrings [ "." ] [ "_" ] HOST;
      DB_USER = config.name;
      DB_PASSWORD = config.mysql.password;
      HOST_USER = config.name;
      HOST_PASSWORD = config.name;
      MAKEFLAGS = "-f Makefile.local";
      DOCKER_REGISTRY = config.domain;
    } // extra; 
  in mapAttrsToList (name: value: { inherit name value; }) env;

  # Base list of packages for devshell, plus extra
  mkPackages = pkgs: extra: [
    pkgs.platform.nf
    pkgs.platform.mysql
    pkgs.platform.mysqldump
    pkgs.doctl
    pkgs.gh
    pkgs.gnumake
    pkgs.nodePackages.nodejs
    # pkgs.nodePackages.webpack-cli
    pkgs.php82Packages.composer
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
  inherit mkConfig mkPkgs mkEnv mkPackages mkServices mkPort;
}
