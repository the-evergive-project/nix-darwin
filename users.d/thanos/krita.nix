{ pkgs, lib, ... }:

{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    base_url="https://cdn.kde.org/ci-builds/graphics/krita/master/macos-universal"
    dmg_name=$(${pkgs.curl}/bin/curl -fsSL "$base_url/" | grep -o 'krita-[^"]*\.dmg' | head -1)

    if [ -z "$dmg_name" ]; then
      echo "krita: failed to resolve latest DMG" >&2
    else
      marker="/var/lib/krita-nix-source"
      if [ ! -f "$marker" ] || [ "$(cat "$marker")" != "$dmg_name" ] || [ ! -d /Applications/krita.app ]; then
        tmp=$(mktemp -d)
        mount_dir=$(mktemp -d)

        echo "krita: downloading $dmg_name..."
        ${pkgs.curl}/bin/curl -fsSL -o "$tmp/$dmg_name" "$base_url/$dmg_name"

        echo "krita: installing..."
        /usr/bin/hdiutil attach "$tmp/$dmg_name" -mountpoint "$mount_dir" -nobrowse -quiet

        app=$(find "$mount_dir" -maxdepth 1 -name "*.app" | head -1)
        if [ -n "$app" ]; then
          app_name=$(basename "$app")
          ${pkgs.rsync}/bin/rsync -a --delete "$app" /Applications/
          /usr/bin/mdimport "/Applications/$app_name"
          echo "$dmg_name" > "$marker"
        else
          echo "krita: no .app found in DMG" >&2
        fi

        /usr/bin/hdiutil detach "$mount_dir" -quiet || true
        rm -rf "$tmp" "$mount_dir"
      fi
    fi
  '';
}
