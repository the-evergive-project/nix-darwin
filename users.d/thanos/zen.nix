{ pkgs, lib, ... }:

let
  zenPolicies = pkgs.writeText "zen-policies.json" (builtins.toJSON {
    policies.SearchEngines = {
      Default = "SearXNG";
      Add = [
        {
          Name = "SearXNG";
          URLTemplate = "https://searxng.local/search?q={searchTerms}";
          Method = "GET";
          IconURL = "https://searxng.local/favicon.ico";
        }
      ];
    };
  });

  zen = pkgs.stdenv.mkDerivation {
    pname = "zen-browser";
    version = "1.19.13b";

    src = pkgs.fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/1.19.13b/zen.macos-universal.dmg";
      sha256 = "1il7wbv8zm392jg15l9qg8h9ryh5sg0m2zkmw5jk9f9ii26q228i";
    };

    nativeBuildInputs = [ pkgs.undmg ];
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
