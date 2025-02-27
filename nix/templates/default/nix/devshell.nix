{ flake, perSystem, pkgs, ... }: let 

  inherit (flake) config;
  inherit (flake.lib) mkShell;

in mkShell flake perSystem {

  startup = ''
    # add your own startup commands
  '';

  # Add your own environment variables
  env = {
    # NF = "example";
  };

  # Add your own commands
  commands = [
    # {
    #   category = "example";
    #   name = "list"; 
    #   command = "ls -lah"; 
    #   help = "list files"; 
    # } 
  ];

  # Add your own packages
  packages = [
    # pkgs.cowsay
  ];

}
