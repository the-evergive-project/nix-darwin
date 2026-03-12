{
  description = "nix-darwin system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager }: let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
    user = {
      name = "thanos"; # enter output of `whoami`
      displayName = "Thanos Kounenis"; # enter your chosen display name
    };
    userConfig = ./users.d + "/${user.name}.nix";
  in {
    darwinConfigurations.evergive = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit user nixpkgs home-manager; };
      modules = [
        ./configuration.nix
      ] ++ nixpkgs.lib.optional (builtins.pathExists userConfig) userConfig;
    };
  };
}
