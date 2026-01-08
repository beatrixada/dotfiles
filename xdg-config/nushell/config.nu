# config.nu
#
# Installed by:
# version = '0.105.1'
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.
use std/util 'path add'
source nix.nu

$env.ENV_CONVERSIONS = {
    ...$env.ENV_CONVERSIONS?
    EDITOR : {
        from_string: { |s| $s | split row ' ' }
        to_string: { |v| $v | str join ' ' }
    }
}

def path_helper [dir] {
    ls $dir | select name | each { |f| open $f.name | split row '\n' } | flatten
}

$env.HOMEBREW_PREFIX = '/opt/homebrew'
$env.HOMEBREW_CELLAR = $'($env.HOMEBREW_PREFIX)/Cellar'
$env.HOMEBREW_REPOSITORY = '/opt/homebrew'
$env.path ++= path_helper /etc/paths.d/
path add $'($env.HOMEBREW_PREFIX)/bin' $'($env.HOMEBREW_PREFIX)/sbin'
path add $'($env.HOME)/Library/Application Support/JetBrains/Toolbox/scripts'
path add $'($env.XDG_DATA_HOME)/cargo/bin'
path add $'($env.HOME)/.local/bin'
path add '/usr/local/bin'

$env.MANPATH = $'($env.MANPATH?):(path_helper /etc/manpaths.d/ | str join ':')'
if ($env.MANPATH | str starts-with ':' | not $in) {
    $env.MANPATH = $':($env.MANPATH)'
}

$env.INFOPATH = $'($env.HOMEBREW_PREFIX)/share/info:($env.INFOPATH?)'

$env.PAGER = 'less -FRX'

# source secrets.nu

let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

$env.config = {
    buffer_editor: $env.EDITOR
    show_banner: false
    history: {
        file_format: "sqlite"
        isolation: true
    }
    completions: {
        external: {
            enable: true
            max_results: 100
            completer: $carapace_completer
        }
    }
}
