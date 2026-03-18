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
      let name = lib.getName pkg; in
      builtins.elem name [
        "vscode"
      ] || lib.hasPrefix "vscode-extension-" name;
  };

  time.timeZone = "Europe/London";
  system.stateVersion = 6;

  users.users.${user.name} = {
    name = user.name;
    home = "/Users/${user.name}";
    description = user.displayName;
  };

  # automatically dev shells upon entering the project directory
  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vscode
    coreutils
  ];
}
