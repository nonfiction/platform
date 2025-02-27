{ flake, inputs, ... }: let 

  # Module args with lib included
  inherit (inputs.nixpkgs) lib;
  args = { inherit flake inputs lib; };

in rec {

  # Resolve tilde to $HOME 
  expand = str: builtins.replaceStrings ["~"] ["$HOME"] str;

  # Bash script helpers
  helpers = ./helpers.sh;

  # Custom merge function that concatenates lists
  merge = import ./merge.nix args;

  # Template for flake configuration
  mkConfig = import ./mkConfig.nix args;

  # Deterministic port number from string
  mkPort = import ./mkPort.nix args;

  # Standard devshell for all platform projects
  mkShell = import ./mkShell.nix args;

  # Preset traefik configs for routers and services
  traefik = import ./traefik.nix args;

  # Generate db init sql to create new user/database
  dbInit = config: pkgs: let  
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
