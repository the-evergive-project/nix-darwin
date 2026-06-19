{
  pkgs,
  lib,
  ...
}: let
  zenHash = "sha256-XTYtIaaFzz/6WRcFgT753bCRJFTHLC7AcatGJ7rIPVA=";
  zenVersion = "1.21.3b";
  zenPolicies = pkgs.writeText "zen-policies.json" (builtins.toJSON {
    policies.ExtensionSettings = {
      "{f0bda7ce-0cda-42dc-9ea8-126b20fed280}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/hister/latest.xpi";
      };
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
      };
      "adguardadblocker@adguard.com" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/adguard-adblocker/latest.xpi";
      };
      "adguard-vpn@adguard.com" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/adguard-vpn/latest.xpi";
      };
      "CanvasBlocker@kkapsner.de" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/canvasblocker/latest.xpi";
      };
    };
    policies.ImportEnterpriseRoots = true;
    policies.Certificates = {
      Install = ["/etc/caddy-ca.crt"];
    };
    policies.SearchEngines = {
      Default = "SearXNG";
      Add = [
        {
          Name = "SearXNG";
          URLTemplate = "https://searxng.internal:3443/search?q={searchTerms}";
          Method = "GET";
          IconURL = "https://searxng.internal:3443/favicon.ico";
        }
      ];
    };
  });

  zen = pkgs.stdenv.mkDerivation {
    pname = "zen-browser";
    version = zenVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${zenVersion}/zen.macos-universal.dmg";
      hash = zenHash;
    };

    nativeBuildInputs = [pkgs.undmg];
    sourceRoot = ".";

    installPhase = ''
      mkdir -p "$out/Applications"
      cp -r Zen.app "$out/Applications/"
      mkdir -p "$out/Applications/Zen.app/Contents/Resources/distribution"
      cp ${zenPolicies} "$out/Applications/Zen.app/Contents/Resources/distribution/policies.json"
    '';

    meta = {
      description = "Zen Browser - a Firefox-based privacy browser";
      homepage = "https://zen-browser.app";
      platforms = pkgs.lib.platforms.darwin;
    };
  };
in {
  system.activationScripts.postActivation.text = lib.mkAfter ''
    src="${zen}/Applications/Zen.app"
    marker="/var/lib/zen-nix-source"

    # Re-install if: marker missing, store path changed (new version), or /Applications/Zen.app was deleted
    if [ ! -f "$marker" ] || [ "$(cat "$marker")" != "$src" ] || [ ! -d /Applications/Zen.app ]; then
      # Copy from the immutable Nix store into /Applications where macOS expects it
      ${pkgs.rsync}/bin/rsync -a --delete "$src" /Applications/
      # Record the store path so we can skip this on the next switch if nothing changed
      echo "$src" > "$marker"
      # Tell Spotlight to index the new app so it appears in searches immediately
      /usr/bin/mdimport /Applications/Zen.app
    fi
  '';
}
