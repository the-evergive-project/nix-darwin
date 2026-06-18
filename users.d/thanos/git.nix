{ pkgs, ... }:

let
  git-mostly-changed =
    let
      script = pkgs.writeShellScriptBin "git-mostly-changed" ''
        git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
      '';
      manpage = pkgs.writeTextFile {
        name = "git-mostly-changed-man";
        destination = "/share/man/man1/git-mostly-changed.1";
        text = ''
          .TH GIT-MOSTLY-CHANGED 1 "2026" "Git Custom Commands" "Git Manual"
          .SH NAME
          git-mostly-changed \- list the 20 most frequently modified files in the past year
          .SH SYNOPSIS
          .B git mostly-changed
          .SH DESCRIPTION
          .B git-mostly-changed
          prints the 20 files with the highest number of distinct commits touching them
          over the past year, sorted in descending order by commit count.
          .PP
          High churn is not inherently problematic; active development produces high churn
          by design.
          The signal to watch for is elevated churn on files that lack clear ownership or
          that consistently resist clean modification.
          Such files accumulate patches on earlier patches; the blast radius of any single
          edit becomes difficult to predict, and time estimates grow accordingly.
          .PP
          Cross-reference the top five results against
          .BR git-bugfix-count (1).
          Files that rank highly on both lists are strong candidates for structural
          refactoring: they change often and they break often.
          .SH SEE ALSO
          .BR git-log (1),
          .BR git-bugfix-count (1)
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "git-mostly-changed";
      paths = [ script manpage ];
    };

  git-contributor-rank =
    let
      script = pkgs.writeShellScriptBin "git-contributor-rank" ''
        git shortlog -sn --no-merges
      '';
      manpage = pkgs.writeTextFile {
        name = "git-contributor-rank-man";
        destination = "/share/man/man1/git-contributor-rank.1";
        text = ''
          .TH GIT-CONTRIBUTOR-RANK 1 "2026" "Git Custom Commands" "Git Manual"
          .SH NAME
          git-contributor-rank \- rank contributors by non-merge commit count
          .SH SYNOPSIS
          .B git contributor-rank
          .SH DESCRIPTION
          .B git-contributor-rank
          invokes
          .BR git-shortlog (1)
          with merge commits excluded and prints all contributors sorted by descending
          commit count.
          .PP
          If a single author accounts for a disproportionate share of commits, the
          project may carry significant bus-factor risk.
          To assess whether that contributor is still active, compare the all-time output
          against a recent window:
          .PP
          .RS
          .nf
          git shortlog \-sn \-\-no\-merges \-\-since="6 months ago"
          .fi
          .RE
          .PP
          An author who dominates the all-time ranking but does not appear in the recent
          window may have departed; institutional knowledge tends to leave with them.
          .PP
          Examine the tail of the list as well as the head.
          A large gap between the number of historical contributors and the number active
          recently may suggest that the team currently maintaining the codebase differs
          significantly from the team that originally built it.
          .SS Caveats
          Squash-merge workflows collapse pull-request authorship into a single commit
          attributed to whoever performed the merge.
          In such repositories this output reflects merge activity rather than individual
          contribution.
          Confirm the team's merge strategy before drawing conclusions.
          .SH SEE ALSO
          .BR git-shortlog (1),
          .BR git-monthly-commits (1)
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "git-contributor-rank";
      paths = [ script manpage ];
    };

  git-bugfix-count =
    let
      script = pkgs.writeShellScriptBin "git-bugfix-count" ''
        git log -i -E --grep="fix|bug|broken" --name-only --format=''' | sort | uniq -c | sort -nr | head -20
      '';
      manpage = pkgs.writeTextFile {
        name = "git-bugfix-count-man";
        destination = "/share/man/man1/git-bugfix-count.1";
        text = ''
          .TH GIT-BUGFIX-COUNT 1 "2026" "Git Custom Commands" "Git Manual"
          .SH NAME
          git-bugfix-count \- list files most frequently touched by bug-fix commits
          .SH SYNOPSIS
          .B git bugfix-count
          .SH DESCRIPTION
          .B git-bugfix-count
          filters the commit log to entries whose messages match the keywords
          .IR fix ,
          .IR bug ,
          or
          .I broken
          (case-insensitive, extended regular expression), then ranks the files touched
          by those commits by frequency.
          The output format is identical to
          .BR git-mostly-changed (1).
          .PP
          Files appearing in both this output and in
          .B git-mostly-changed
          output represent the highest-risk areas of the codebase: they change
          frequently and they break frequently, yet have not received a structural
          resolution.
          .SS Caveats
          Output quality is directly proportional to commit message discipline.
          Repositories where messages carry no semantic content will produce sparse or
          empty results.
          Even an incomplete map of defect density provides more signal than no map.
          .SH SEE ALSO
          .BR git-log (1),
          .BR git-mostly-changed (1)
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "git-bugfix-count";
      paths = [ script manpage ];
    };

  git-monthly-commits =
    let
      script = pkgs.writeShellScriptBin "git-monthly-commits" ''
        git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
      '';
      manpage = pkgs.writeTextFile {
        name = "git-monthly-commits-man";
        destination = "/share/man/man1/git-monthly-commits.1";
        text = ''
          .TH GIT-MONTHLY-COMMITS 1 "2026" "Git Custom Commands" "Git Manual"
          .SH NAME
          git-monthly-commits \- show commit frequency grouped by calendar month
          .SH SYNOPSIS
          .B git monthly-commits
          .SH DESCRIPTION
          .B git-monthly-commits
          prints the number of commits per calendar month across the full history of the
          repository, sorted chronologically.
          .PP
          The shape of the output is as informative as the absolute numbers.
          Common patterns and their interpretations:
          .TP
          .B Steady cadence
          Consistent month-over-month counts suggest a continuously active team.
          .TP
          .B Sharp single-month drop
          A sudden large reduction may indicate a key contributor departure, a project
          pause, or a significant disruption to team capacity.
          .TP
          .B Gradual decline over 6\(en12 months
          Sustained reduction in velocity may suggest the team is losing momentum or
          headcount.
          .TP
          .B Periodic spikes with intervening quiet periods
          May indicate release-driven batching rather than continuous delivery.
          .PP
          This command surfaces organisational and team patterns rather than code
          quality metrics.
          Correlating significant inflection points against known events \(em
          departures, reorganisations, funding changes \(em builds a timeline of the
          project's development history that is otherwise difficult to reconstruct.
          .SH SEE ALSO
          .BR git-log (1),
          .BR git-contributor-rank (1)
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "git-monthly-commits";
      paths = [ script manpage ];
    };

  git-firefighting-commits =
    let
      script = pkgs.writeShellScriptBin "git-firefighting-commits" ''
        git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
      '';
      manpage = pkgs.writeTextFile {
        name = "git-firefighting-commits-man";
        destination = "/share/man/man1/git-firefighting-commits.1";
        text = ''
          .TH GIT-FIREFIGHTING-COMMITS 1 "2026" "Git Custom Commands" "Git Manual"
          .SH NAME
          git-firefighting-commits \- list crisis-keyword commits from the past year
          .SH SYNOPSIS
          .B git firefighting-commits
          .SH DESCRIPTION
          .B git-firefighting-commits
          searches the past year of commit messages for the keywords
          .IR revert ,
          .IR hotfix ,
          .IR emergency ,
          and
          .I rollback
          (case-insensitive) and prints the matching one-line summaries.
          .PP
          An occasional occurrence is expected in any active codebase.
          A high frequency of such commits may indicate that the team's release process
          is unreliable or that rollback is more difficult than it should be.
          .PP
          An empty result is also meaningful.
          It may indicate a mature, well-tested release process, or it may indicate that
          commit messages are too terse to match.
          Consult
          .BR git-monthly-commits (1)
          and
          .BR git-contributor-rank (1)
          for supporting context before interpreting an empty result.
          .SH EXIT STATUS
          Returns 1 if no matching commits are found (exit status propagated from
          .BR grep (1)).
          .SH SEE ALSO
          .BR git-log (1),
          .BR grep (1),
          .BR git-bugfix-count (1)
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "git-firefighting-commits";
      paths = [ script manpage ];
    };
in

{
  home.packages = [ git-mostly-changed git-contributor-rank git-bugfix-count git-monthly-commits git-firefighting-commits ];

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
      alias = {
        mostly-changed = "!git-mostly-changed";
        contributor-rank = "!git-contributor-rank";
        bugfix-count = "!git-bugfix-count";
        monthly-commits = "!git-monthly-commits";
        firefighting-commits = "!git-firefighting-commits";
      };
    };
  };
}
