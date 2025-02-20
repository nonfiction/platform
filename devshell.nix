{ flake, perSystem, pkgs, ... }: let 

  inherit (pkgs.lib) mkDefault getExe;
  inherit (builtins) toString;
  inherit (flake) config;

in perSystem.devshell.mkShell {

  devshell.name = mkDefault "platform";

  env = [
    { name = "MAKEFLAGS"; value = "-f Makefile.local"; }
    { name = "DOCKER_REGISTRY"; value = config.domain; }
    { name = "DB_HOST"; value = "127.0.0.1"; }
    { name = "DB_PORT"; value = toString config.mysql.port; }
    { name = "DB_PASSWORD"; value = config.mysql.password; }
  ];

  commands = let 
    mysqladmin = builtins.toString [
      "${pkgs.mysql80}/bin/mysqladmin"
      "--user=root"
      "--password=${config.mysql.password}"
      "--socket=${config.dataDir}/mysql.sock"
    ];
  in [
    {
      name = "mysqld-stop";
      command = "${mysqladmin} shutdown";
      help = "force mysqld shutdown";
    }
  ];

  packages = [
    perSystem.self.nf
    perSystem.self.mysql
    perSystem.self.mysqldump
    pkgs.doctl
    pkgs.gh
    pkgs.gnumake
    pkgs.nodePackages.nodejs
    # pkgs.nodePackages.webpack-cli
    pkgs.php82Packages.composer
    # pkgs.traefik
  ];
  # motd = "";

  serviceGroups.platform.services = {
    mysqld.command = "${getExe perSystem.self.mysqld}";
    traefik.command = "${getExe perSystem.self.traefik}";
    adminer.command = "${getExe perSystem.self.adminer}";
  };

}
