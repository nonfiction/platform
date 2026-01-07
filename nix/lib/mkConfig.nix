{flake, ...}: name:
# Template for flake configuration
flake.lib.merge rec {
  inherit name; # project name
  domain = "local.nfweb.ca"; # base domain
  host = "${name}.${domain}";
  wp.uploadsDir = "${dataDir}/uploads/${name}"; # wp uploads
  wp.port = flake.lib.mkPort name; # published port
  mysql.socket = "${dataDir}/mysql.sock"; # alternative to port
  mysql.username = "nonfiction"; # additional db user
  mysql.password = "x"; # simple password for localhost
  mysql.dump = "${dataDir}/${name}.sql"; # database dumps
  mysql.database = builtins.replaceStrings ["."] ["_"] host;
  adminer.port = 8885; # database manager
  traefik.port = 8886; # traefik dashboard
  traefik.http.port = 8887; # redirects to https
  traefik.https.port = 8888; # https reverse proxy
  traefik.email = "dns@nonfiction.ca"; # acme
  dataDir = "~/.local/share/platform"; # base directory
  secrets = ["DO_AUTH_TOKEN"]; # list of secret env variables
}
flake.lib.config or {}
