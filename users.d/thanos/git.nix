{ ... }:

{
  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      core.editor = "nvim";
      core.excludesFile = "~/.config/git/ignore";
      core.pager = "delta";
      delta.navigate = true;
      delta.dark = true;
      interactive.diffFilter = "delta --color-only";
      merge.conflictStyle = "zdiff3";
      pull.rebase = true;
    };
  };
}
