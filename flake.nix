# https://github.com/numtide/blueprint
{
  description = "nonfiction Platform";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs: inputs.blueprint { inherit inputs; prefix = "./nix"; } // {
    config = inputs.self.lib.mkConfig "platform"; 
  };
}
