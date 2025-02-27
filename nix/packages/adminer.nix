{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake.lib) expand traefik;
  inherit (flake) config;
  dataDir = "${expand config.dataDir}/traefik";

  adminer = toString [
    "${pkgs.php}/bin/php"
    "-S 0.0.0.0:${toString config.adminer.port}"
    "${pkgs.adminer-pematon}/index.php"
  ];

  yaml = (pkgs.formats.yaml {}).generate "adminer.yaml" {
    http.routers.adminer = traefik.router "db" config.domain // {
      service = "adminer";
    };
    http.services.adminer = traefik.service config.adminer.port;
  };

in pkgs.writeScriptBin "adminer" ''
  #!/usr/bin/env bash
  mkdir -p ${dataDir}
  ln -sf ${yaml} ${dataDir}/adminer.yaml
  exec ${adminer} 
''
