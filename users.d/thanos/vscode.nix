{ pkgs, lib, ... }:

let
  # VSCode settings - edit these to change your settings
  vscodeSettings = {
    "update.mode" = "none";
    "chat.customAgentInSubagent.enabled" = true;
    "json.schemaDownload.trustedDomains" = {
      "https://schemastore.azurewebsites.net/" = true;
      "https://raw.githubusercontent.com/" = true;
      "https://www.schemastore.org/" = true;
      "https://json.schemastore.org/" = true;
      "https://json-schema.org/" = true;
      "https://biomejs.dev" = true;
    };
  };

  settingsJson = builtins.toJSON vscodeSettings;
  settingsPath = "Library/Application Support/Code/User/settings.json";
in
{
  programs.vscode = {
    enable = true;
    # vscode is installed system-wide via configuration.nix; this stub prevents
    # home-manager from adding a duplicate copy to the user profile
    package = pkgs.runCommand "vscode-noop" { } "mkdir $out";
    profiles = {
      default = {
        extensions = with pkgs.vscode-extensions; [
          # Languages
          jnoortheen.nix-ide
        ];

        # Note: Extensions not available in nixpkgs (claude-code, biome, prisma, etc.)
        # can be installed manually through VS Code and will persist across
        # rebuilds
      };
    };
  };

  # Copy settings.json instead of symlinking (makes it writable)
  # Settings are overwritten on each darwin-rebuild, but VSCode can modify them between rebuilds
  home.activation.vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/Library/Application Support/Code/User"
    rm -f "$HOME/${settingsPath}"
    cp ${pkgs.writeText "vscode-settings.json" settingsJson} "$HOME/${settingsPath}"
    chmod 644 "$HOME/${settingsPath}"
  '';
}
