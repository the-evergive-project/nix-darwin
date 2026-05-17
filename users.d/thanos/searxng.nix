{ pkgs, ... }:

{
  home.packages = [ pkgs.searxng ];

  launchd.agents.searxng = {
    enable = true;
    config = {
      Label = "searxng";
      ProgramArguments = [ "${pkgs.searxng}/bin/searxng-run" ];
      EnvironmentVariables = {
        SEARXNG_SETTINGS_PATH = "${./searxng/settings.yml}";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/searxng.log";
      StandardErrorPath = "/tmp/searxng.err";
    };
  };
}
