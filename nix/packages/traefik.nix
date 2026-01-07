{
  flake,
  pkgs,
  ...
}: let
  inherit (flake) config lib;
  dataDir = lib.expand config.dataDir;

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
    "--entryPoints.traefik.address=:${toString config.traefik.port}"

    # Create entrypoints http/https listening on ports from config
    "--entryPoints.web.address=:${toString config.traefik.http.port}"
    "--entryPoints.web.http.redirections.entryPoint.to=websecure"
    "--entryPoints.web.http.redirections.entryPoint.scheme=https"
    "--entryPoints.websecure.address=:${toString config.traefik.https.port}"

    # Support auto-renewing https certificates
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge=true"
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge.provider=digitalocean"
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge.delayBeforeCheck=45"
    "--certificatesResolvers.resolver-dns.acme.dnsChallenge.disablePropagationCheck=true"
    "--certificatesResolvers.resolver-dns.acme.storage=${dataDir}/acme.json"
    "--certificatesResolvers.resolver-dns.acme.email=${config.traefik.email}"

    # Watch configuration files
    "--providers.file.watch=true"
    "--providers.file.directory=${dataDir}/traefik"
  ];

  yaml = (pkgs.formats.yaml {}).generate "dashboard.yaml" {
    # Dashboard
    http.routers.dashboard =
      lib.traefik.router "" config.domain
      // {
        service = "api@internal";
      };
    http.services.dashboard = lib.traefik.service config.traefik.port;
  };
in
  pkgs.writeScriptBin "traefik"
  # bash
  ''
    #!/usr/bin/env bash
    export DO_AUTH_TOKEN
    mkdir -p ${dataDir}/traefik
    ln -sf ${yaml} ${dataDir}/traefik/traefik.yaml
    exec ${traefik} ''${@}
  ''
