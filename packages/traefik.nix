{ pkgs, ... }: let
  dataDir = "$HOME/.local/share/platform";

  traefik = builtins.toString [
    "${pkgs.traefik}/bin/traefik"
    "--log.level=DEBUG"
    "--api.dashboard=true"
    "--api.insecure=true"
    "--entryPoints.traefik.address=:8886"
    "--entryPoints.web.address=:8887"
    "--entryPoints.web.http.redirections.entryPoint.to=websecure"
    "--entryPoints.web.http.redirections.entryPoint.scheme=https"
    "--entryPoints.websecure.address=:8888"
    "--entryPoints.websecure.http.tls.certResolver=do_resolver"
    "--entryPoints.websecure.http.tls.domains.main=\"local.nfweb.ca\""
    "--entryPoints.websecure.http.tls.domains.sans=\"*.local.nfweb.ca\""
    "--providers.docker.exposedByDefault=false"
    "--providers.docker.network=proxy"
    "--providers.file.watch=true"
    "--providers.file.directory=${dataDir}/traefik"
    "--certificatesresolvers.digitalocean.acme.email=dns@nonfiction.ca"
    "--certificatesresolvers.digitalocean.acme.caServer=https://acme-v02.api.letsencrypt.org/directory"
    "--certificatesresolvers.digitalocean.acme.dnsChallenge.provider=digitalocean"
    "--certificatesresolvers.digitalocean.acme.dnsChallenge.delayBeforeCheck=0"
    "--certificatesresolvers.digitalocean.acme.storage=${dataDir}/acme.json"
  ];

in pkgs.writeScriptBin "traefik" ''
  #!/usr/bin/env bash
  export DO_AUTH_TOKEN
  mkdir -p ${dataDir}/traefik
  cp -f ${./traefik.yml} ${dataDir}/traefik/traefik.yml
  exec ${traefik} ''${@} 
''
