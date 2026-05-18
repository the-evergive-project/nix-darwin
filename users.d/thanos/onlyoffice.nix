{ pkgs, lib, ... }:

let
  onlyoffice = pkgs.stdenv.mkDerivation {
    pname = "onlyoffice-desktopeditors";
    version = "9.3.1";

    src = pkgs.fetchurl {
      url = "https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v9.3.1/ONLYOFFICE-arm.dmg";
      sha256 = "19yxg7zdg4b9fhfc6qfw0wdbm1wifa697z0mh0cknxp9x2ijfr9f";
    };

    nativeBuildInputs = [ pkgs.undmg ];
    sourceRoot = ".";

    installPhase = ''
      mkdir -p "$out/Applications"
      cp -r ONLYOFFICE.app "$out/Applications/"
    '';

    meta = {
      description = "OnlyOffice Desktop Editors";
      homepage = "https://www.onlyoffice.com";
      platforms = pkgs.lib.platforms.darwin;
    };
  };
in {
  system.activationScripts.postActivation.text = lib.mkAfter ''
    src="${onlyoffice}/Applications/ONLYOFFICE.app"
    marker="/var/lib/onlyoffice-nix-source"
    if [ ! -f "$marker" ] || [ "$(cat "$marker")" != "$src" ] || [ ! -d /Applications/ONLYOFFICE.app ]; then
      ${pkgs.rsync}/bin/rsync -a --delete "$src" /Applications/
      echo "$src" > "$marker"
      /usr/bin/mdimport /Applications/ONLYOFFICE.app
    fi
  '';
}
