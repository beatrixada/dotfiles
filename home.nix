{
  config,
  pkgs,
  stablePkgs,
  user,
  userPackages,
  extraNushellConfig,
  claude-code,
  codex-cli-nix,
  lib,
  idris2,
  idris2Lsp,
  idris2Packages,
  buildIdris,
  buildIdris',
  ...
}:
with lib;
let
  gradle8 = pkgs.writeShellScriptBin "gradle8" ''
    exec ${pkgs.gradle_8}/bin/gradle "$@"
  '';
  unfreePackages = [
    pkgs._1password-cli
    pkgs.claude-code
  ];
  launchctl-setenv = pkgs.writeShellScriptBin "launchctl-setenv" (
    concatStringsSep "\n" (
      mapAttrsToList (
        name: val: "/bin/launchctl setenv ${name} ${toString val}"
      ) config.home.sessionVariables
    )
  );
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  news.display = "silent";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) (lib.map (p: lib.getName p) unfreePackages);
  nixpkgs.overlays = [
    claude-code.overlays.default

    (final: prev: {
      fish = stablePkgs.fish; # until https://nixpkgs-tracker.ocfox.me/?pr=462589 lands in unstable
    })
  ];
  home.packages =
    userPackages
    ++ unfreePackages
    ++ [
      (import ./packages/jdk-mission-control.nix { inherit pkgs; })
    ]
    ++ [
      # idris2
      # idris2Lsp
      # idris2Packages.pack
    ]
    ++ [ codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default ]
    ++ (with pkgs; [
      # buck2 (broken)
      chezmoi
      devenv
      difftastic
      dua
      duckdb
      elixir_1_19
      emacs
      erlang_28
      flyctl
      gemini-cli
      gh
      gradle8
      hyperfine
      innoextract
      jira-cli-go
      jq
      liquibase
      mas
      maven
      meld
      micronaut
      mitmproxy
      mvnd
      natscli
      ncdu
      nil
      nixd
      nixfmt
      nixfmt-tree
      nmap
      nodejs_24
      # ollama
      openssh
      ouch
      pandoc
      pgformatter
      pinentry_mac
      poppler-utils
      python314
      quarkus
      rustup
      scc
      shellcheck
      shfmt
      skaffold
      source-code-pro
      spring-boot-cli
      sqlite
      unar
      visualvm
      xdg-ninja
      # # Adds the 'hello' command to your environment. It prints a friendly
      # # "Hello, world!" when run.
      # pkgs.hello

      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
    ]);

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    ".zshenv".text = ''
      export ZDOTDIR=${config.xdg.configHome}/zsh
      . "$ZDOTDIR"/.zshenv
    '';
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  launchd.agents.launchctl-setenv = {
    enable = true;
    config = {
      ProgramArguments = [ "${launchctl-setenv}/bin/launchctl-setenv" ];
      KeepAlive.SuccessfulExit = false;
      RunAtLoad = true;
    };
  };

  xdg = {
    enable = true;
    configFile = {
      "fish/config.fish".source = xdg-config/fish/config.fish;
      "ghostty/config".text = ''
        macos-option-as-alt = left
        keybind = alt+left=esc:b
        keybind = alt+right=esc:f
        font-family = "PragmataPro Mono"
        font-size = 14
        font-feature = -calt
        font-feature = -liga
        font-feature = -dlig
        scrollback-limit = 1_000_000_000
        auto-update = download
        auto-update-channel = tip
        command = ${pkgs.nushell}/bin/nu
        keybind = shift+enter=text:\n
      '';
      "nushell/nix.nu".source = xdg-config/nushell/nix.nu;
      "powershell".source = xdg-config/powershell;
      "python".source = xdg-config/python;
      "zsh" = {
        source = xdg-config/zsh;
        recursive = true;
      };
    };

    dataFile = {
      my-gradle_8-install = {
        source = "${pkgs.gradle_8}/lib/gradle";
      };
      my-maven-install = {
        source = "${pkgs.maven}";
      };
      my-gradle-install = {
        source = "${pkgs.gradle_9}/lib/gradle";
      };
      my-gradle-jdk = {
        source = pkgs.gradle_9.jdk.home;
      };
    };
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/ada/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "'/opt/homebrew/bin/zed --wait --new'";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    CP_HOME_DIR = "${config.xdg.dataHome}/cocoapods";
    DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    VAGRANT_HOME = "${config.xdg.dataHome}/vagrant";
    FLY_CONFIG_DIR = "${config.xdg.stateHome}/fly";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    DOOMDIR = "${config.xdg.configHome}/home-manager/doom";
  };

  home.shellAliases = {
  };

  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    # awscli.enable = true;
    bash.enable = true;
    java.enable = true;
    jujutsu.enable = true;
    ripgrep.enable = true;
    uv.enable = true;
    carapace = {
      enable = true;
      enableNushellIntegration = false;
    };
    direnv = {
      enable = true;
      enableNushellIntegration = false;
      enableBashIntegration = false;
    };
    gradle = {
      enable = true;
      home = "${lib.removePrefix "${config.home.homeDirectory}/" config.xdg.dataHome}/gradle";
      package = pkgs.gradle_9;
    };
    mise = {
      enable = true;
      enableNushellIntegration = false;
    };
    nushell = {
      enable = true;
      configFile.source = xdg-config/nushell/config.nu;
      extraConfig = extraNushellConfig;
    };
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
}
