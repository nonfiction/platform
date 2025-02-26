{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake.lib) expand traefik;
  cfg = flake.config;
  dataDir = "${expand cfg.dataDir}/traefik";

  adminer = toString [
    "${pkgs.php}/bin/php"
    "-S 0.0.0.0:${toString cfg.adminer.port}"
    "${pkgs.adminer-pematon}/index.php"
  ];

  yaml = (pkgs.formats.yaml {}).generate "adminer.yaml" {
    http.routers.adminer = traefik.router "db" cfg.domain // {
      service = "adminer";
    };
    http.services.adminer = traefik.service cfg.adminer.port;
  };

in pkgs.writeScriptBin "adminer" ''
  #!/usr/bin/env bash
  mkdir -p ${dataDir}
  ln -sf ${yaml} ${dataDir}/adminer.yaml
  exec ${adminer} 
''
