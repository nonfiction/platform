{ flake, perSystem, ... }: let 

  inherit (flake) config;
  pkgs = flake.lib.mkPkgs perSystem;

in perSystem.devshell.mkShell {

  devshell.name = config.name;
  devshell.startup.platform = flake.lib.startup pkgs config;

  env = flake.lib.mkEnv config {
    NAME = config.name; 
  };

  commands = flake.lib.mkCommands config [];

  packages = flake.lib.mkPackages pkgs [
    pkgs.cowsay
  ];

}
