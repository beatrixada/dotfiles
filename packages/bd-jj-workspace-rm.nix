{ pkgs }:

pkgs.writeScriptBin "bd-jj-workspace-rm" ''
  #!${pkgs.nushell}/bin/nu

  # Remove a jj workspace created by bd-jj-workspace
  # Usage: bd-jj-workspace-rm <workspace_path> [repo_path]
  def main [workspace_path: string, repo_path?: string] {
      let ws_abs = ($workspace_path | path expand)

      # Infer repo_path if not provided by looking for .jj in workspace
      let repo = if ($repo_path != null) {
          $repo_path | path expand
      } else {
          # Try to read the repo path from the workspace's .jj directory
          let jj_dir = $"($ws_abs)/.jj"
          if ($jj_dir | path exists) {
              # jj stores the repo path - we can get it from jj itself
              let result = (do { jj workspace root --repository $ws_abs } | complete)
              if $result.exit_code == 0 {
                  # The workspace knows its repo, but we need the main repo
                  # Infer from naming convention: parent/reponame-wsname -> parent/reponame
                  let ws_name = ($ws_abs | path basename)
                  let parent = ($ws_abs | path dirname)
                  # Find the base repo name by removing the -suffix
                  let parts = ($ws_name | split row '-')
                  if ($parts | length) > 1 {
                      let base_name = ($parts | drop 1 | str join '-')
                      let inferred = $"($parent)(char path_sep)($parts | first)"
                      if ($inferred | path exists) {
                          $inferred
                      } else {
                          print $"Error: Could not infer repo path. Please provide repo_path explicitly."
                          exit 1
                      }
                  } else {
                      print $"Error: Could not infer repo path from workspace name. Please provide repo_path explicitly."
                      exit 1
                  }
              } else {
                  print $"Error: Could not determine repo path. Please provide repo_path explicitly."
                  exit 1
              }
          } else {
              print $"Error: ($ws_abs) does not appear to be a jj workspace. Please provide repo_path explicitly."
              exit 1
          }
      }

      # Get the workspace name (jj uses the directory basename as the workspace name)
      let ws_name = ($ws_abs | path basename)

      # Forget the workspace in jj
      print $"Forgetting workspace '($ws_name)' from repo ($repo)..."
      jj workspace forget $ws_name --repository $repo

      # Remove the workspace directory
      print $"Removing directory ($ws_abs)..."
      rm -rf $ws_abs

      print $"Workspace '($ws_name)' removed successfully."
  }
''
