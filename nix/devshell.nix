{ flake, perSystem, ... }: let 

  inherit (flake.lib) mkPkgs mkEnv mkPackages mkServices;
  inherit (flake) config;
  pkgs = mkPkgs perSystem;

in perSystem.devshell.mkShell {

  devshell.name = config.name;
  # motd = "";

  env = mkEnv config {
    NAME = config.name; 
  };

  commands = [];

  packages = mkPackages pkgs [
    pkgs.cowsay
  ];

  serviceGroups = mkServices pkgs {
    web.services = {
      ping.command = "ping ${config.domain}";
    };
  };

}
