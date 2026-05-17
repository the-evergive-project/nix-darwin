{ pkgs, ... }:

let
  caddyfile = pkgs.writeText "Caddyfile" ''
    http://searxng.local {
      reverse_proxy 127.0.0.1:24652
    }
  '';
in {
  networking.hosts = {
    "127.0.0.1" = [ "searxng.local" ];
  };

  launchd.daemons.caddy = {
    serviceConfig = {
      Label = "caddy";
      ProgramArguments = [
        "${pkgs.caddy}/bin/caddy"
        "run"
        "--config" "${caddyfile}"
        "--adapter" "caddyfile"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/caddy.log";
      StandardErrorPath = "/var/log/caddy.err";
    };
  };
}
