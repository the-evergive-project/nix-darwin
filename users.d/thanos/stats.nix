{ config, ... }:

{
  # Disable Stats auto-update — it can't update in the read-only nix store
  # and would otherwise download a DMG to ~/Downloads on every launch.
  targets.darwin.defaults."eu.exelban.Stats" = {
    SUEnableAutomaticChecks = false;
    SUAutomaticallyUpdate = false;
    SUScheduledCheckInterval = 0;
    "update-interval" = "Notify"; # prevents silent DMG downloads; Stats still notifies but won't download
  };

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
}
