{ config, pkgs, lib, user, nixpkgs, home-manager, ... }:
let
  userDir = ./andrew;
in {
  imports = [
    home-manager.darwinModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit nixpkgs; };
  home-manager.backupFileExtension = "backup";

  home-manager.users.${user.name} = { config, lib, ... }: {
    home.username = lib.mkForce "a.morrison";
    home.homeDirectory = lib.mkForce "/Users/a.morrison";
    home.stateVersion = "23.11";

    home.packages = with pkgs; [
      neovim
      lazygit
      git
      fzf
      fd
      ripgrep
      starship
      (pkgs.claude-code.overrideAttrs (old: rec {
        version = "2.1.77";
        src = pkgs.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-3bsFS3EZYbU8htlO7QtA9Qs8xlm0ZPz02bJ3ROZaugY=";
        };
        npmDepsHash = lib.fakeHash;
      }))
    ];

    home.activation.lazyVimSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/.config/nvim" ]; then
        ${pkgs.git}/bin/git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
        rm -rf "$HOME/.config/nvim/.git"
      fi
    '';

    programs.home-manager.enable = true;
    programs.starship = {
      enable = true;
    };
    programs.git = {
      enable = true;
    };

    programs.zsh = {
      enable = true;
      initContent = ''
        export PATH="$HOME/.local/bin:$PATH"
      '';
    };
  };
}
