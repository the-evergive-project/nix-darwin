{
  description = "nix-darwin system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin }: let
    system = "aarch64-darwin";
    user = {
      name = "{username}"; # enter output of `whoami`
      displayName = "{display_name}"; # enter your chosen display name
    };
  in {
    darwinConfigurations.evergive = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit user; };
      modules = [
        ./configuration.nix
      ];
    };
  };
}
