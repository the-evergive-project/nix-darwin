{
  pkgs,
  user,
  config,
  lib,
  ...
}: {
  nix = {
    channel.enable = false;
    optimise.automatic = true;
    gc.automatic = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];
  };

  nixpkgs.config = {
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        claude-code
      ];
  };

  time.timeZone = "Europe/London";

  users.users.${user.name} = {
    description = user.displayName;
  };

  # automatically dev shells upon entering the project directory
  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [
    git
    claude-code
    vscode
  ];
}
