{ flake, perSystem, ... }: let 

  inherit (flake.lib) mkPkgs mkEnv mkPackages mkServices;
  inherit (flake) config;
  pkgs = mkPkgs perSystem;

in perSystem.devshell.mkShell {

  devshell.name = "platform";
  # motd = "";

  env = mkEnv config {
    NAME = "platform";
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
