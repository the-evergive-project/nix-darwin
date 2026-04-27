{ config, pkgs, lib, user, nixpkgs, home-manager, ... }:

let
  userDir = ./thanos;
in {
  imports = [
    home-manager.darwinModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit nixpkgs; };

  # Configure home-manager for this user
  home-manager.users.${user.name} = { config, ... }: {
    imports = [
      (userDir + "/vscode.nix")
    ];

    home.username = lib.mkForce "thanos";
    home.homeDirectory = lib.mkForce "/Users/thanos";
    home.stateVersion = "23.11";

    # Packages for user environment
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
      neovim
      nushell
      pay-respects
      ranger
      ripgrep
      sd
      skim
      stats
      tmux
      tree
      watch
      zsh-history-substring-search
    ];

    # Program configurations
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.fzf = {
      colors = {
        "bg+" = "#363a4f";
        "bg" = "#24273a";
        "spinner" = "#f4dbd6";
        "hl" = "#ed8796";
        "fg" = "#cad3f5";
        "header" = "#ed8796";
        "info" = "#c6a0f6";
        "pointer" = "#f4dbd6";
        "marker" = "#f4dbd6";
        "fg+" = "#cad3f5";
        "prompt" = "#c6a0f6";
        "hl+" = "#ed8796";
      };
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];
      enable = true;
      enableZshIntegration = true;
    };

    programs.home-manager.enable = true;

    programs.git = {
      enable = true;
      signing.format = "openpgp";
      settings = {
        core.editor = "nvim";
        core.excludesFile = "~/.config/git/ignore";
        core.pager = "delta";
        delta.navigate = true;
        delta.dark = true;
        interactive.diffFilter = "delta --color-only";
        merge.conflictStyle = "zdiff3";
        pull.rebase = true;
      };
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      history = {
        size = 10000;
        save = 10000;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
        extended = true;
      };
      sessionVariables = {
        SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
        EDITOR = "nvim";
      };
      initContent = builtins.readFile (userDir + "/zshrc");
      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "v1.1.2";
            sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
          };
        }
      ];
      shellAliases = {
        ls = "eza";
      };
      syntaxHighlighting.enable = true;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };

    programs.starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile (userDir + "/starship.toml"));
    };

    # Disable Home Manager's default ~/Applications/Home Manager Apps symlink
    targets.darwin.linkApps.enable = false;

    # Disable Stats auto-update — it can't update in the read-only nix store
    # and would otherwise download a DMG to ~/Downloads on every launch.
    targets.darwin.defaults."eu.exelban.Stats" = {
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
      SUScheduledCheckInterval = 0;
    };

    # LaunchAgents for apps that should start at login
    launchd.agents.stats = {
      enable = true;
      config = {
        Label = "eu.exelban.Stats";
        # The createAppWrappers activation names the launcher script "launch", not "Stats"
        ProgramArguments = [ "${config.home.homeDirectory}/Applications/Nix Darwin Apps/Stats.app/Contents/MacOS/launch" ];
        RunAtLoad = true;
        KeepAlive = false;
      };
    };
  };
}
