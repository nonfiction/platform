{
  flake,
  pkgs,
  ...
}: let
  inherit (builtins) toString;
  inherit (flake.lib) expand traefik;
  inherit (flake) config;
  dataDir = "${expand config.dataDir}/traefik";
  socket = "${expand config.dataDir}/mysql.sock";

  # https://github.com/adminerevo/adminerevo/issues/190
  phpIni = pkgs.writeText "adminer-php.ini" ''
    mysqli.default_socket = ${socket}
    mysql.default_socket = ${socket}
    pdo_mysql.default_socket = ${socket}
  '';

  adminer = toString [
    "${pkgs.php}/bin/php"
    "-c ${phpIni}"
    "-S 0.0.0.0:${toString config.adminer.port}"
    "${pkgs.adminneo}/index.php"
  ];

  yaml = (pkgs.formats.yaml {}).generate "adminer.yaml" {
    http.routers.adminer =
      traefik.router "db" config.domain
      // {
        service = "adminer";
      };
    http.services.adminer = traefik.service config.adminer.port;
  };
in
  pkgs.writeScriptBin "adminer"
  # bash
  ''
    #!/usr/bin/env bash
    mkdir -p ${dataDir}
    ln -sf ${yaml} ${dataDir}/adminer.yaml
    exec ${adminer}
  ''
