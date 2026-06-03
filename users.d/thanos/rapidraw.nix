{ pkgs, lib, ... }:

{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    src="${pkgs.rapidraw}/Applications/RapidRAW.app"
    marker="/var/lib/rapidraw-nix-source"
    if [ ! -f "$marker" ] || [ "$(cat "$marker")" != "$src" ] || [ ! -d /Applications/RapidRAW.app ]; then
      ${pkgs.rsync}/bin/rsync -a --delete "$src" /Applications/
      echo "$src" > "$marker"
      /usr/bin/mdimport /Applications/RapidRAW.app
    fi
  '';
}
