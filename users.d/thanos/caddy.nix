{ pkgs, lib, ... }:

let
  caddyfile = pkgs.writeText "Caddyfile" ''
    searxng.local {
      tls internal
      reverse_proxy 127.0.0.1:24652
    }
  '';
  searxngHosts = pkgs.writeText "searxng-hosts" ''
    127.0.0.1 searxng.local
  '';
in {
  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${pkgs.hostctl}/bin/hostctl replace searxng --from ${searxngHosts} 2>/dev/null || \
      ${pkgs.hostctl}/bin/hostctl add searxng --from ${searxngHosts}
    for _i in $(seq 1 15); do
      /usr/bin/curl -sf http://localhost:2019/config/ >/dev/null 2>&1 && break
      sleep 1
    done
    ${pkgs.caddy}/bin/caddy trust 2>/dev/null || true
  '';

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
      EnvironmentVariables = {
        HOME = "/var/root";
      };
    };
  };
}
