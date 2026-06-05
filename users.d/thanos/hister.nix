{ ... }:

{
  services.hister = {
    enable = true;
    port = 4433;
    settings.app.search_url = "https://searxng.internal:3443/search?q={query}";
    settings.server.base_url = "https://hister.internal:3443";
    settings.indexer.directories = [
      { path = "/Users/thanos/Work/projects"; filetypes = [ "md" "txt" "org" ]; }
    ];
  };

}
