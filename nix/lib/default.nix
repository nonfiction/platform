args@{ flake, inputs, ... }: let 

  inherit (builtins) replaceStrings toString;
  inherit (inputs.nixpkgs) lib;
  inherit (lib) concatStringsSep filter getExe mapAttrsToList;

in rec {

  # Template for flake configuration
  mkConfig = import ./mkConfig.nix args;

  # Deterministic port number from string
  mkPort = import ./mkPort.nix args;

  # Standard devshell for all platform projects
  mkShell = import ./mkShell.nix args;

  # Bash script helpers
  helpers = ./helpers.sh;

  # Resolve tilde to $HOME 
  expand = str: replaceStrings ["~"] ["$HOME"] str;

  # Preset config for traefik router
  traefik.router = sub: domain: {
    entryPoints = [ "websecure" ];
    rule = "Host(`${concatStringsSep "." (filter (x: x != "") [ sub domain ])}`)";
    tls.certresolver = "resolver-dns";
    tls.domains = [{ main = "${domain}"; sans = "*.${domain}"; }];
  };

  # Preset config for traefik service
  traefik.service = port: {
    loadBalancer.servers = [{ 
      url = "http://0.0.0.0:${toString port}";
    }];
  };

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


}
