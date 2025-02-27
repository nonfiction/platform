{ lib, ... }: let 

  inherit (builtins) toString;
  inherit (lib) concatStringsSep filter;

in {

  # Preset config for traefik router
  router = sub: domain: {
    entryPoints = [ "websecure" ];
    rule = "Host(`${concatStringsSep "." (filter (x: x != "") [ sub domain ])}`)";
    tls.certresolver = "resolver-dns";
    tls.domains = [{ main = "${domain}"; sans = "*.${domain}"; }];
  };

  # Preset config for traefik service
  service = port: {
    loadBalancer.servers = [{ 
      url = "http://0.0.0.0:${toString port}";
    }];
  };

}
