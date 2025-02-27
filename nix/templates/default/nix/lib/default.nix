{ flake, inputs, ... }: let 

  # Module args with lib included
  inherit (inputs.nixpkgs) lib; 
  args = { inherit flake inputs lib; };

# Extend platform lib
# https://github.com/nonfiction/platform/blob/v2/nix/lib/default.nix
in inputs.platform.lib // rec {

  # Override default config:
  # https://github.com/nonfiction/platform/blob/v2/nix/lib/mkConfig.nix
  config = {};

  # Add custom lib functions
  # foo = arg: "my foo is ${arg}";
  # bar = import ./bar.nix args;

}
