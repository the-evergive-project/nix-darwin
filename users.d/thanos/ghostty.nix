{ ... }: {
  system.activationScripts.installGhostty.text = ''
    ghostty_app="/Applications/Ghostty.app"
    # Tracks the GitHub release ID of the installed tip build so that
    # new tip releases are picked up automatically on each rebuild.
    marker="/var/lib/.ghostty-tip-id"

    tip_id=$(curl -fsSL "https://api.github.com/repos/ghostty-org/ghostty/releases/tags/tip" \
      | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")

    stored_id=""
    if [ -f "$marker" ]; then
      stored_id=$(cat "$marker")
    fi

    if [ ! -d "$ghostty_app" ] || { [ -n "$tip_id" ] && [ "$tip_id" != "$stored_id" ]; }; then
      echo "Installing Ghostty (tip)..." >&2
      tmp_dmg=$(mktemp /tmp/ghostty.XXXXXX.dmg)
      curl -fsSL "https://github.com/ghostty-org/ghostty/releases/download/tip/Ghostty.dmg" -o "$tmp_dmg"
      mount_point=$(mktemp -d /tmp/ghostty-mount.XXXXXX)
      hdiutil attach -quiet -nobrowse -mountpoint "$mount_point" "$tmp_dmg"
      cp -R "$mount_point/Ghostty.app" /Applications/
      hdiutil detach -quiet "$mount_point"
      rm -f "$tmp_dmg"
      rmdir "$mount_point"
      [ -n "$tip_id" ] && echo "$tip_id" > "$marker"
      echo "Ghostty installed" >&2
    fi
  '';
}
