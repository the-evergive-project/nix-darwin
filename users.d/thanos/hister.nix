{ pkgs, hister, ... }:

let
  histerPkg = hister.packages.${pkgs.system}.hister;
in {
  services.hister = {
    enable = true;
    port = 4433;
    settings.app.search_url = "https://searxng.local/search?q={query}";
    settings.server.base_url = "https://hister.local";
    settings.indexer.directories = [
      { path = "/Users/thanos/Work/projects"; filetypes = [ "md" "txt" "org" ]; }
    ];
  };

  launchd.agents.hister-import-browser = {
    serviceConfig = {
      Label = "hister-import-browser";
      ProgramArguments = [
        "${histerPkg}/bin/hister" "import-browser" "zen"
        "/Users/thanos/Library/Application Support/Zen/Profiles/iso6opxm.Default (release)/places.sqlite"
      ];
      StartInterval = 60;
      RunAtLoad = true;
      StandardOutPath = "/tmp/hister-import-browser.log";
      StandardErrorPath = "/tmp/hister-import-browser.err";
    };
  };
}
