{
  description = "nonfiction Platform";
  inputs = {

    # https://github.com/NixOS/nixpkgs/
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # https://github.com/numtide/devshell/
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/numtide/blueprint
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.blueprint { inherit inputs; prefix = "./nix"; } // {
    config = inputs.self.lib.mkConfig "platform"; 
  };
}
