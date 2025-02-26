{ flake, pkgs, ... }: let

  inherit (builtins) toString;
  cfg = flake.config;
  dataDir = flake.lib.expand cfg.dataDir;

  traefik = toString [
    "${pkgs.traefik}/bin/traefik"

    # Enable the Traefik log, for configurations and errors
    "--log.level=DEBUG"

    # Allow backend services to serve https with self-signed certs
    "--serversTransport.insecureSkipVerify=true"

    # Enable Docker in Traefik, so that it reads labels from Docker container
    "--providers.docker=true"
    "--providers.docker.exposedByDefault=false"
    "--providers.docker.network=proxy"

    # Enable the Dashboard and API
    "--api.dashboard=true"
    "--api.insecure=true"
    "--entryPoints.traefik.address=:${toString cfg.traefik.port}"

    # Create entrypoints http/https listening on ports from config
    "--entryPoints.web.address=:${toString cfg.traefik.http.port}"
    "--entryPoints.web.http.redirections.entryPoint.to=websecure"
    "--entryPoints.web.http.redirections.entryPoint.scheme=https"
    "--entryPoints.websecure.address=:${toString cfg.traefik.https.port}"
    
    # Support auto-renewing https certificates
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge=true"
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge.provider=digitalocean"
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge.delayBeforeCheck=0"
    "--certificatesResolvers.resolver-dns.acme.storage=${dataDir}/acme.json"
    "--certificatesResolvers.resolver-dns.acme.email=${cfg.traefik.email}"

    # Watch configuration files
    "--providers.file.watch=true"
    "--providers.file.directory=${dataDir}/traefik"

  ];

  yaml = (pkgs.formats.yaml {}).generate "dashboard.yaml" {

    # Dashboard
    http.routers.dashboard = flake.lib.traefik.router "" cfg.domain // {
      service = "api@internal";
    };
    http.services.dashboard = flake.lib.traefik.service cfg.traefik.port;

  };


in pkgs.writeScriptBin "traefik" ''
  #!/usr/bin/env bash
  export DO_AUTH_TOKEN
  mkdir -p ${dataDir}/traefik
  ln -sf ${yaml} ${dataDir}/traefik/traefik.yaml
  exec ${traefik} ''${@} 
''
