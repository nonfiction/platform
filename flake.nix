# https://github.com/numtide/blueprint
{
  description = "nonfiction Platform";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs: inputs.blueprint { inherit inputs; } // {
    config = {
      dataDir = "$HOME/.local/share/platform";
      adminer.port = 8885;
      mysql.port = 25060;
      mysql.username = "nonfiction";
      mysql.password = "x";
      traefik.domain = "local.nfweb.ca";
      traefik.email = "dns@nonfiction.ca";
      traefik.port = 8886;
      traefik.http.port = 8887;
      traefik.https.port = 8888;
    };
  };
}
