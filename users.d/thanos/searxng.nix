{ pkgs, config, ... }:

let
  innerScript = pkgs.writeShellScript "searxng-start" ''
    tmp=$(mktemp /tmp/searxng-XXXXXX)
    ${pkgs.gettext}/bin/envsubst '$SEARXNG_SECRET_KEY' < ${./searxng/settings.yml} > "$tmp"
    SEARXNG_SETTINGS_PATH="$tmp" exec ${pkgs.searxng}/bin/searxng-run
  '';
in {
  home.packages = [ pkgs.searxng ];

  launchd.agents.searxng = {
    enable = true;
    config = {
      Label = "searxng";
      ProgramArguments = [
        "${pkgs.sops}/bin/sops"
        "exec-env"
        "${./sops/secrets.env}"
        "${innerScript}"
      ];
      EnvironmentVariables = {
        SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/searxng.log";
      StandardErrorPath = "/tmp/searxng.err";
    };
  };
}
