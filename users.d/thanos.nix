{ config, pkgs, lib, user, nixpkgs, home-manager, hister, ... }:

let
  userDir = ./thanos;
in {
  imports = [
    home-manager.darwinModules.home-manager
    hister.darwinModules.hister
    (userDir + "/caddy.nix")
    (userDir + "/ghostty.nix")
    (userDir + "/hister.nix")
    # (userDir + "/krita.nix")
    (userDir + "/onlyoffice.nix")
    # (userDir + "/rapidraw.nix")
    (userDir + "/zen.nix")
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
      bitwarden-cli
      bat
      biome
      btop
      claude-code
      cloc
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
      sops
      stats
      tmux
      tree
      watch
      zed-editor
      nixd # Nix LSP server (for VSCode autocomplete)
      zsh-history-substring-search
    ];

    home.file.".config/ghostty/config".source = userDir + "/ghostty/config";

    programs.home-manager.enable = true;

    # Disable Home Manager's default ~/Applications/Home Manager Apps symlink
    targets.darwin.linkApps.enable = false;
  };

  system.defaults.NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = true;
}
