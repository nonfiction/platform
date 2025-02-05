{
  description = "nonfiction Platform";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  outputs = { self, nixpkgs }: let

    # Helper function to create outputs for each supported system
    forAllSystems = nixpkgs.lib.genAttrs [ 
      "aarch64-darwin" 
      "x86_64-darwin" 
      "x86_64-linux" 
    ];

    # Create scripts derivation for a given system
    mkPlatform = pkgs: pkgs.stdenv.mkDerivation {
      name = "platform";
      src = ./cli; # directory containing most script
      swarmSrc = ./swarm; # additional scripts found here
      installPhase = ''
        mkdir -p $out/bin
        cp -r $src/* $out/bin/
        mkdir -p $out/swarm
        cp -r $swarmSrc/* $out/swarm/
        chmod +x $out/bin/*
      '';
    };

  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs { inherit system; };
      platform = mkPlatform pkgs;
      deps = with pkgs; lib.makeBinPath [ 
        apacheHttpd 
        docker 
        doctl 
        esh 
        gh
        git 
        jq
        mariadb 
      ];
    in {
      nf = pkgs.writeScriptBin "nf" ''
        #!/usr/bin/env bash
        export PATH=${deps}:${platform}/bin:$PATH
        exec ${platform}/bin/nf ''${@}
      '';
    });

  };
}

