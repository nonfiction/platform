{ perSystem, pkgs, ... }: let 

  inherit (pkgs.lib) mkDefault getExe;

in perSystem.devshell.mkShell {

  devshell.name = mkDefault "platform";

  env = [
    { name = "MAKEFLAGS"; value = "-f Makefile.local"; }
    { name = "DOCKER_REGISTRY"; value = "local.nfweb.ca"; }
    { name = "DB_HOST"; value = "127.0.0.1"; }
    { name = "DB_PORT"; value = "25060"; }
    { name = "DB_PASSWORD"; value = "x"; }
  ];

  commands = let 
    mysqladmin = builtins.toString [
      "${pkgs.mysql80}/bin/mysqladmin"
      "--user=root"
      "--socket=$HOME/.local/share/platform/mysql.sock"
    ];
  in [
    {
      name = "mysqld-stop";
      command = "${mysqladmin} --password=x shutdown";
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
    pkgs.traefik
  ];
  # motd = "";

  serviceGroups.platform.services = {
    mysqld.command = "${getExe perSystem.self.mysqld}";
    traefik.command = "${getExe perSystem.self.traefik}";
    adminer.command = "${getExe perSystem.self.adminer}";
  };

}
