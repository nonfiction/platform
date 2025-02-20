{ flake, inputs, ... }: let 

  inherit (builtins) toString;
  inherit (inputs.nixpkgs) lib;
  inherit (lib) getExe mapAttrsToList;

  mkPkgs = perSystem: 
    perSystem.nixpkgs // { platform = perSystem.platform or perSystem.self; };

  mkEnv = config: extra: [
    { name = "MAKEFLAGS"; value = "-f Makefile.local"; }
    { name = "DOCKER_REGISTRY"; value = config.domain; }
    { name = "DB_HOST"; value = "127.0.0.1"; }
    { name = "DB_PORT"; value = toString config.mysql.port; }
    { name = "DB_PASSWORD"; value = config.mysql.password; }
  ] ++ mapAttrsToList (name: value: { inherit name value; }) extra;

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
