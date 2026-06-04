{ pkgs, lib, ... }:

let
  caddyfile = pkgs.writeText "Caddyfile" ''
    {
      admin localhost:2018
    }

    searxng.internal:3443 {
      tls internal
      reverse_proxy 127.0.0.1:24652
    }

    hister.internal:3443 {
      tls internal
      reverse_proxy 127.0.0.1:4433
    }
  '';
  searxngHosts = pkgs.writeText "searxng-hosts" ''
    127.0.0.1 searxng.internal
  '';
  histerHosts = pkgs.writeText "hister-hosts" ''
    127.0.0.1 hister.internal
  '';
in {
  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${pkgs.hostctl}/bin/hostctl replace searxng --from ${searxngHosts} 2>/dev/null || \
      ${pkgs.hostctl}/bin/hostctl add searxng --from ${searxngHosts}
    ${pkgs.hostctl}/bin/hostctl replace hister --from ${histerHosts} 2>/dev/null || \
      ${pkgs.hostctl}/bin/hostctl add hister --from ${histerHosts}
    # Remove stale Caddy CA entries so only the current CA ends up trusted
    security find-certificate -a -c "Caddy" -Z /Library/Keychains/System.keychain 2>/dev/null | \
      awk '/SHA-1 hash:/{print $NF}' | \
      while IFS= read -r hash; do
        security delete-certificate -Z "$hash" /Library/Keychains/System.keychain 2>/dev/null || true
      done
    for _i in $(seq 1 15); do
      /usr/bin/curl -sf http://localhost:2018/config/ >/dev/null 2>&1 && break
      sleep 1
    done
    ${pkgs.caddy}/bin/caddy trust --address localhost:2018 2>/dev/null || true
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
