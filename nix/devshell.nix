{ flake, perSystem, ... }: let 

  inherit (flake) config;
  pkgs = flake.lib.mkPkgs perSystem;

in perSystem.devshell.mkShell {

  devshell.name = config.name;
  devshell.startup.platform = flake.lib.startup pkgs config;

  env = flake.lib.mkEnv config {
    NAME = config.name; 
  };

  commands = [{ 
    name = "platform";
    help = "launch platform and attach";
    command = "process-compose -D && process-compose attach";
  }];

  packages = flake.lib.mkPackages pkgs [
    pkgs.cowsay
  ];

}
