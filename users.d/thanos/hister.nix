{ pkgs, ... }:

let
  histerRulesScript = pkgs.writeText "hister-rules-init.py" ''
    import json, os

    rules_file = "/Users/thanos/Library/Application Support/hister/rules.json"
    pattern = "searxng\\.internal"

    if os.path.exists(rules_file):
        with open(rules_file) as f:
            rules = json.load(f)
    else:
        os.makedirs(os.path.dirname(rules_file), exist_ok=True)
        rules = {"skip": [], "priority": [], "versioning": [], "aliases": {}}

    skip = rules.get("skip", [])
    if isinstance(skip, list) and pattern not in skip:
        skip.append(pattern)
        rules["skip"] = skip
        with open(rules_file, "w") as f:
            json.dump(rules, f, indent=2)
  '';
in
{
  services.hister = {
    enable = true;
    port = 4433;
    settings.app.search_url = "https://searxng.internal:3443/search?q={query}";
    settings.server.base_url = "https://hister.internal:3443";
    settings.indexer.directories = [
      { path = "/Users/thanos/Work/projects"; filetypes = [ "md" "txt" "org" ]; excludes = [ ".git" "node_modules" "vendor" "bun" ]; }
    ];
  };

  # URL skip rules live in rules.json, not in the YAML config (the Rules struct
  # is tagged yaml:"-" so settings.* can't reach it). This script idempotently
  # adds the searxng pattern on every rebuild without clobbering rules added
  # via the UI.
  system.activationScripts.histerSkipRules.text = ''
    su -l thanos -c "${pkgs.python3}/bin/python3 ${histerRulesScript}"
  '';
}
