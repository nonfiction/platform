{ flake, perSystem, ... }: let 

  cfg = flake.config;
  pkgs = flake.lib.mkPkgs perSystem;

in perSystem.devshell.mkShell {

  devshell.name = cfg.name;
  devshell.startup.platform = flake.lib.startup cfg pkgs; 

  env = flake.lib.mkEnv cfg pkgs {
    NAME = cfg.name; 
  };

  commands = flake.lib.mkCommands cfg pkgs [];

  packages = flake.lib.mkPackages cfg pkgs [
    pkgs.cowsay
  ];

}
