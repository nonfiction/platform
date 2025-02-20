{ flake, inputs, ... }: let 

  inherit (builtins) replaceStrings toString;
  inherit (inputs.nixpkgs) lib;
  inherit (lib) getExe mapAttrsToList;

  mkPkgs = perSystem: 
    perSystem.nixpkgs // { platform = perSystem.platform or perSystem.self; };

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

  mkServices = pkgs: extra: {
    platform.services = {
      mysqld.command = "${getExe pkgs.platform.mysqld}";
      traefik.command = "${getExe pkgs.platform.traefik}";
      adminer.command = "${getExe pkgs.platform.adminer}";
    };
  } // extra;

  mkPort = str: let
    hash = builtins.hashString "sha256" str;
    firstChar = builtins.substring 0 1 hash;
    baseNum = builtins.stringLength (builtins.head (builtins.split firstChar "abcdef0123456789"));
    hashNum = baseNum * (builtins.stringLength hash);
    portRange = 65535 - 49152;
  in 49152 + (hashNum - (portRange * (hashNum / portRange)));

in {
  inherit mkEnv mkPkgs mkPackages mkServices mkPort;
}
