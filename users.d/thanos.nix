{ config, pkgs, lib, user, nixpkgs, home-manager, ... }:

let
  userDir = ./thanos;
in {
  imports = [
    home-manager.darwinModules.home-manager
    (userDir + "/caddy.nix")
    (userDir + "/ghostty.nix")
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit nixpkgs; };

  home-manager.users.${user.name} = { config, ... }: {
    imports = [
      (userDir + "/direnv.nix")
      (userDir + "/fzf.nix")
      (userDir + "/git.nix")
      (userDir + "/nvim.nix")
      (userDir + "/searxng.nix")
      (userDir + "/stats.nix")
      (userDir + "/vscode.nix")
      (userDir + "/zsh.nix")
    ];

    home.username = lib.mkForce "thanos";
    home.homeDirectory = lib.mkForce "/Users/thanos";
    home.stateVersion = "23.11";

    home.packages = with pkgs; [
      # The current bitwarden-cli package is broken, use specific version instead
      bitwarden-cli
      bat
      biome
      btop
      claude-code
      ctop
      delta
      direnv
      eza
      fd
      firefox
      fzf
      git
      himalaya # terminal mail client
      lazygit
      mtr
      nushell
      pay-respects
      ranger
      ripgrep
      rsync
      sd
      skim
      stats
      tmux
      tree
      watch
      nixd # Nix LSP server (for VSCode autocomplete)
      zsh-history-substring-search
    ];

    programs.home-manager.enable = true;

    # Disable Home Manager's default ~/Applications/Home Manager Apps symlink
    targets.darwin.linkApps.enable = false;
  };
}
