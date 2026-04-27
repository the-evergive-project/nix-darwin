{ lib, ... }: {
  system.activationScripts.postActivation.text = lib.mkAfter ''
    {
      set -euo pipefail
      echo "[$(date)] installGhostty started"

      ghostty_app="/Applications/Ghostty.app"
      # Tracks the GitHub release ID of the installed tip build so that
      # new tip releases are picked up automatically on each rebuild.
      marker="/var/lib/.ghostty-tip-id"

      tip_id=$(/usr/bin/curl -fsSL "https://api.github.com/repos/ghostty-org/ghostty/releases/tags/tip" \
        | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
      echo "tip_id=''${tip_id:-<empty>}"

      stored_id=""
      if [ -f "$marker" ]; then
        stored_id=$(cat "$marker")
      fi
      echo "stored_id=''${stored_id:-<empty>}"

      if [ ! -d "$ghostty_app" ] || { [ -n "$tip_id" ] && [ "$tip_id" != "$stored_id" ]; }; then
        echo "Installing Ghostty (tip)..."

        tmp_dmg=$(/usr/bin/mktemp /tmp/ghostty.XXXXXX.dmg)
        mount_point=""
        trap '
          echo "EXIT trap: cleaning up"
          /bin/rm -f "$tmp_dmg"
          if [ -n "$mount_point" ]; then
            /usr/bin/hdiutil detach "$mount_point" -quiet 2>/dev/null || true
          fi
        ' EXIT

        echo "Downloading..."
        /usr/bin/curl -fL "https://github.com/ghostty-org/ghostty/releases/download/tip/Ghostty.dmg" -o "$tmp_dmg"
        echo "Download complete ($(du -h "$tmp_dmg" | cut -f1))"

        echo "Mounting..."
        mount_point=$(/usr/bin/hdiutil attach -nobrowse -noverify "$tmp_dmg" | /usr/bin/awk 'END {print $NF}')
        echo "Mounted at: $mount_point"

        echo "Copying to /Applications..."
        /bin/cp -R "$mount_point/Ghostty.app" /Applications/
        echo "Copy complete"

        /usr/bin/hdiutil detach "$mount_point" -quiet
        trap - EXIT
        /bin/rm -f "$tmp_dmg"

        [ -n "$tip_id" ] && echo "$tip_id" > "$marker"
        echo "Ghostty installed successfully"
      else
        echo "Ghostty is up to date, skipping"
      fi

      echo "[$(date)] installGhostty finished"
    } >> /tmp/ghostty-install.log 2>&1
  '';
}
