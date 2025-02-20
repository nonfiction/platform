{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake) config;

  adminer = toString [
    "${pkgs.php}/bin/php"
    "-S 0.0.0.0:${toString config.adminer.port}"
    "${pkgs.adminer-pematon}/index.php"
  ];

  yaml = (pkgs.formats.yaml {}).generate "adminer.yaml" {
    http.routers.adminer = {
      rule = "Host(`db.${config.domain}`)";
      service = "adminer";
      entryPoints = [ "websecure" ];
      tls = {};
    };
    http.services.adminer = {
      loadBalancer.servers = [{ 
        url = "http://0.0.0.0:${toString config.adminer.port}";
      }];
    };
  };

in pkgs.writeScriptBin "adminer" ''
  #!/usr/bin/env bash
  mkdir -p ${config.dataDir}/traefik
  ln -sf ${yaml} ${config.dataDir}/traefik/adminer.yaml
  exec ${adminer} 
''
