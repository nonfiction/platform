{
  description = "Wordpress site";

  inputs = {
    # https://github.com/NixOS/nixpkgs/
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # https://github.com/numtide/blueprint/
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/numtide/devshell/
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/nonfiction/platform
    platform.url = "github:nonfiction/platform";
    platform.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      prefix = "./nix";
    }
    // {
      config = inputs.platform.lib.mkConfig "mywebsite";
    };
}
