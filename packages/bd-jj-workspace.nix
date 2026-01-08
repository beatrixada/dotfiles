{ pkgs }:

pkgs.writeScriptBin "bd-jj-workspace" ''
  #!${pkgs.nushell}/bin/nu

  # Create a jj workspace with bd redirect for parallel agent development
  # Usage: bd-jj-workspace <name> [repo_path]
  def main [name: string, repo_path?: string] {
      let repo = ($repo_path | default ".")
      let repo_abs = ($repo | path expand)
      let repo_name = ($repo_abs | path basename)
      let workspace_path = $"($repo_abs | path dirname)(char path_sep)($repo_name)-($name)"
      let main_beads = $"($env.HOME)/SwiftlyInc/.beads"

      # Create jj workspace
      jj workspace add --repository $repo $workspace_path

      # Set up bd redirect
      mkdir $"($workspace_path)/.beads"
      $main_beads | save -f $"($workspace_path)/.beads/redirect"

      print $"Created workspace: ($workspace_path)"
      print $"bd redirect configured to: ($main_beads)"
  }
''
