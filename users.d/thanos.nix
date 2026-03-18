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

    # Create wrapper apps that launch the real nix store apps
    # Wrappers have proper icons and are indexed by Spotlight
    home.activation.createAppWrappers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      dest_folder="${config.home.homeDirectory}/Applications/Nix Darwin Apps"

      echo "Recreating ~/Applications/Nix Darwin Apps..."
      rm -rf "$dest_folder"
      mkdir -p "$dest_folder"

      # Find .app bundles from home.packages and create wrappers
      for pkg in ${toString config.home.packages}; do
        if [ -d "$pkg/Applications" ]; then
          for app in "$pkg"/Applications/*.app; do
            if [ -e "$app" ]; then
              app_name=$(basename "$app" .app)
              echo "  Creating wrapper for $app_name..."

              wrapper="$dest_folder/$app_name.app"
              mkdir -p "$wrapper/Contents/MacOS"
              mkdir -p "$wrapper/Contents/Resources"

              # Get icon filename from original app's Info.plist
              icon_file=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$app/Contents/Info.plist" 2>/dev/null || echo "")
              # Add .icns extension if missing
              if [ -n "$icon_file" ] && [[ "$icon_file" != *.icns ]]; then
                icon_file="$icon_file.icns"
              fi
              # Copy the icon
              if [ -n "$icon_file" ] && [ -f "$app/Contents/Resources/$icon_file" ]; then
                cp "$app/Contents/Resources/$icon_file" "$wrapper/Contents/Resources/AppIcon.icns"
              else
                # Fallback: find any .icns file
                icns=$(/usr/bin/find "$app/Contents/Resources" -name "*.icns" -print -quit 2>/dev/null)
                if [ -n "$icns" ]; then
                  cp "$icns" "$wrapper/Contents/Resources/AppIcon.icns"
                fi
              fi

              # Create Info.plist
              cat > "$wrapper/Contents/Info.plist" << EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleExecutable</key>
        <string>launch</string>
        <key>CFBundleIconFile</key>
        <string>AppIcon</string>
        <key>CFBundleIdentifier</key>
        <string>org.nix.$app_name.wrapper</string>
        <key>CFBundleName</key>
        <string>$app_name</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleVersion</key>
        <string>1.0</string>
    </dict>
    </plist>
    EOF

              # Create launcher script
              cat > "$wrapper/Contents/MacOS/launch" << EOF
    #!/bin/bash
    open "$app"
    EOF
              chmod +x "$wrapper/Contents/MacOS/launch"
            fi
          done
        fi
      done

      echo "Done! App wrappers are in ~/Applications/Nix Darwin Apps."
    '';

    # LaunchAgents for apps that should start at login
    launchd.agents.stats = {
      enable = true;
      config = {
        Label = "eu.exelban.Stats";
        ProgramArguments = [ "${config.home.homeDirectory}/Applications/Nix Darwin Apps/Stats.app/Contents/MacOS/Stats" ];
        RunAtLoad = true;
        KeepAlive = false;
      };
    };
  };
}
