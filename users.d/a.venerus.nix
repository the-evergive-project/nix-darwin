{ config, pkgs, lib, user, nixpkgs, home-manager, ... }:

{
  imports = [
    home-manager.darwinModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit nixpkgs; };

  home-manager.users.${user.name} = { config, ... }: {
    home.username = lib.mkForce "a.venerus";
    home.homeDirectory = lib.mkForce "/Users/a.venerus";
    home.stateVersion = "23.11";

    home.packages = with pkgs; [
      git
    ];

    programs.home-manager.enable = true;

    programs.git = {
      enable = true;
    };

    programs.zsh = {
      enable = true;
    };
  };
}
