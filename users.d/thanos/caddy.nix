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
    # Wait for Caddy to generate its local CA cert (up to 30s)
    caddy_ca="/var/root/Library/Application Support/Caddy/pki/authorities/local/root.crt"
    for _i in $(seq 1 30); do
      [ -f "$caddy_ca" ] && break
      sleep 1
    done
    if [ -f "$caddy_ca" ]; then
      cp "$caddy_ca" /etc/caddy-ca.crt
      # Remove stale Caddy CA entries so only the current CA ends up trusted
      security find-certificate -a -c "Caddy" -Z /Library/Keychains/System.keychain 2>/dev/null | \
        awk '/SHA-1 hash:/{print $NF}' | \
        while IFS= read -r hash; do
          security delete-certificate -Z "$hash" /Library/Keychains/System.keychain 2>/dev/null || true
        done
      security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /etc/caddy-ca.crt 2>/dev/null || true
    fi
  '';

  launchd.daemons.caddy = {
    serviceConfig = {
      Label = "caddy";
      ProgramArguments = [
        "/bin/sh" "-c"
        "/bin/wait4path /nix/store && exec ${pkgs.caddy}/bin/caddy run --config ${caddyfile} --adapter caddyfile"
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
