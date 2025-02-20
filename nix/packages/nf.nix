{ pkgs, ... }: let

  # Create scripts derivation for a given system
  platform = pkgs.stdenv.mkDerivation {
    name = "platform";
    src = ../../cli; # directory containing most script
    swarmSrc = ../../swarm; # additional scripts found here
    installPhase = ''
      mkdir -p tmp/bin
      cp -r $src/* tmp/bin/
      mkdir -p tmp/swarm
      cp -r $swarmSrc/* tmp/swarm/

      find tmp/bin -type f -exec ${pkgs.perl}/bin/perl -pi -e 's/\$\(bin\//\$\(nf /g' {} +

      mkdir -p $out/bin
      cp -r tmp/bin/* $out/bin/
      mkdir -p $out/swarm
      cp -r tmp/swarm/* $out/swarm/
      chmod +x $out/bin/*
    '';
  };

  path = with pkgs; lib.makeBinPath [ 
    apacheHttpd 
    docker 
    doctl 
    esh 
    gh
    git 
    jq
    # mariadb 
    mysql80
  ];

in pkgs.writeScriptBin "nf" ''
  #!/usr/bin/env bash
  export PATH=${path}:${platform}/bin:$PATH
  exec ${platform}/bin/nf ''${@}
''
