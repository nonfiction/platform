{ flake, perSystem, pkgs, ... }: let 

  inherit (flake) config;
  inherit (flake.lib) mkShell;

# Example creating devshell
in mkShell flake perSystem {

  # Example appending to the startup script
  startup = ''
    echo "Hello world!"
  '';

  # Example of adding an environment variable
  env = {
    FOO = "bar";
  };

  # Example of adding a command
  commands = [{ 
    name = "list"; 
    command = "ls -lah"; 
    help = "list files"; 
  }];

  # Example of adding a package
  packages = [ 
    pkgs.cowsay 
  ];
}
