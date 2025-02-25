{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  cfg = flake.config;
  dataDir = flake.lib.expand cfg.dataDir;

  traefik = toString [
    "${pkgs.traefik}/bin/traefik"
    "--log.level=DEBUG"
    "--api.dashboard=true"
    "--api.insecure=true"
    "--entryPoints.traefik.address=:${toString cfg.traefik.port}"
    "--entryPoints.web.address=:${toString cfg.traefik.http.port}"
    "--entryPoints.web.http.redirections.entryPoint.to=websecure"
    "--entryPoints.web.http.redirections.entryPoint.scheme=https"
    "--entryPoints.websecure.address=:${toString cfg.traefik.https.port}"
    "--entryPoints.websecure.http.tls.certResolver=do_resolver"
    "--entryPoints.websecure.http.tls.domains.main=\"${cfg.domain}\""
    "--entryPoints.websecure.http.tls.domains.sans=\"*.${cfg.domain}\""
    "--providers.docker.exposedByDefault=false"
    "--providers.docker.network=proxy"
    "--providers.file.watch=true"
    "--providers.file.directory=${dataDir}/traefik"
    "--certificatesresolvers.digitalocean.acme.email=${cfg.traefik.email}"
    "--certificatesresolvers.digitalocean.acme.caServer=https://acme-v02.api.letsencrypt.org/directory"
    "--certificatesresolvers.digitalocean.acme.dnsChallenge.provider=digitalocean"
    "--certificatesresolvers.digitalocean.acme.dnsChallenge.delayBeforeCheck=0"
    "--certificatesresolvers.digitalocean.acme.storage=${dataDir}/acme.json"
  ];

  yaml = (pkgs.formats.yaml {}).generate "dashboard.yaml" {
    http.routers.dashboard = {
      rule = "Host(`${cfg.domain}`)";
      service = "dashboard";
      entryPoints = [ "websecure" ];
      tls = {};
    };
    http.services.dashboard = {
      loadBalancer.servers = [{ 
        url = "http://0.0.0.0:${toString cfg.traefik.https.port}";
      }];
    };
  };

in pkgs.writeScriptBin "traefik" ''
  #!/usr/bin/env bash
  export DO_AUTH_TOKEN
  mkdir -p ${dataDir}/traefik
  ln -sf ${yaml} ${dataDir}/traefik/traefik.yaml
  exec ${traefik} ''${@} 
''
