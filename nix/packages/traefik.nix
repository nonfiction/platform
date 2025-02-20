{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  inherit (flake) config;

  traefik = toString [
    "${pkgs.traefik}/bin/traefik"
    "--log.level=DEBUG"
    "--api.dashboard=true"
    "--api.insecure=true"
    "--entryPoints.traefik.address=:${toString config.traefik.port}"
    "--entryPoints.web.address=:${toString config.traefik.http.port}"
    "--entryPoints.web.http.redirections.entryPoint.to=websecure"
    "--entryPoints.web.http.redirections.entryPoint.scheme=https"
    "--entryPoints.websecure.address=:${toString config.traefik.https.port}"
    "--entryPoints.websecure.http.tls.certResolver=do_resolver"
    "--entryPoints.websecure.http.tls.domains.main=\"${config.domain}\""
    "--entryPoints.websecure.http.tls.domains.sans=\"*.${config.domain}\""
    "--providers.docker.exposedByDefault=false"
    "--providers.docker.network=proxy"
    "--providers.file.watch=true"
    "--providers.file.directory=${config.dataDir}/traefik"
    "--certificatesresolvers.digitalocean.acme.email=${config.traefik.email}"
    "--certificatesresolvers.digitalocean.acme.caServer=https://acme-v02.api.letsencrypt.org/directory"
    "--certificatesresolvers.digitalocean.acme.dnsChallenge.provider=digitalocean"
    "--certificatesresolvers.digitalocean.acme.dnsChallenge.delayBeforeCheck=0"
    "--certificatesresolvers.digitalocean.acme.storage=${config.dataDir}/acme.json"
  ];

  yaml = (pkgs.formats.yaml {}).generate "dashboard.yaml" {
    http.routers.dashboard = {
      rule = "Host(`${config.domain}`)";
      service = "dashboard";
      entryPoints = [ "websecure" ];
      tls = {};
    };
    http.services.dashboard = {
      loadBalancer.servers = [{ 
        url = "http://0.0.0.0:${toString config.traefik.https.port}";
      }];
    };
  };

in pkgs.writeScriptBin "traefik" ''
  #!/usr/bin/env bash
  export DO_AUTH_TOKEN
  mkdir -p ${config.dataDir}/traefik
  ln -sf ${yaml} ${config.dataDir}/traefik/traefik.yaml
  exec ${traefik} ''${@} 
''
