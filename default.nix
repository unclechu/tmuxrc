# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import nix/sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
{ callPackage
, runCommand
, writeTextFile
, lib
, findutils
, tmuxPlugins
, tmux

# Overridable dependencies
, __nix-utils ? callPackage sources.nix-utils {}

# ↓ Build options ↓

, __srcConfigFile ? ./.tmux.conf

# Make ‘tmuxsh’ available for calling it manually (inside ‘tmux’ session).
# This is not necessary if you add ‘tmuxsh’ to ‘environment.systemPackages’ in
# your NixOS ‘configuration.nix’ for instance. Also this is for executable
# version only, in ‘configuration.nix’ you set just tmux config file
# (to ‘programs.tmux.extraConfig’) and this dependency wouldn’t be provided
# anyway if you don’t add it to ‘environment.systemPackages’.
, with-tmuxsh ? false
}:
let
  inherit (__nix-utils) esc lines unlines wrapExecutable shellCheckers;

  # ‘tmuxsh’ for the tmux config itself, without ‘tmux-conf-file’ argument.
  # Otherwise it would be a recursive dependency.
  # ‘tmuxsh rc’ that tmux config is calling doesn’t depend on that argument.
  tmuxsh = callPackage nix/apps/tmuxsh.nix {
    inherit __nix-utils;
    tmux-conf-file = null;
  };

  tmuxsh-exe = "${tmuxsh}/bin/tmuxsh";
  replace-tmuxsh = builtins.replaceStrings [ "tmuxsh" ] [ tmuxsh-exe ];

  pluginsSplit =
    let
      initial = { place = "pre"; pre = []; plugins = []; post = []; };

      result =
        builtins.foldl' reducer initial
          (lines (replace-tmuxsh (builtins.readFile __srcConfigFile)));

      reducer = acc: line: acc // (
        if acc.place == "pre"
        then if line == "# PLUGINS:BEGIN"
             then { place = "plugins"; }
             else { pre = acc.pre ++ [line]; }
        else

        if acc.place == "plugins"
        then if line == "# PLUGINS:END"
             then { place = "post"; }
             else let match = builtins.match "set -g @plugin '.+/(.+)'" line;
                  in  if isNull match
                      then {}
                      else { plugins = [ (builtins.elemAt match 0) ]; }
        else

        if acc.place == "post"
        then { post = acc.post ++ [line]; }
        else throw "Unexpected ‘place’ during parsing: ‘${acc.place}’"
      );
    in
      assert result.place == "post";
      lib.filterAttrs (n: v: n != "place") result;

  pluginsLoadingCommandsFile =
    let
      find = "${findutils}/bin/find";

      plugins = builtins.concatStringsSep "\n" (
        builtins.map (x: tmuxPlugins.${x}) pluginsSplit.plugins
      );
    in
      runCommand "tmux-plugin-imports" {
        inherit plugins;
        passAsFile = [ "plugins" ];
      } ''
        set -Eeuo pipefail || exit
        readarray -t PLUGINS < "$pluginsPath"

        for plugin in "''${PLUGINS[@]}"; do
          if ! [[ -d $plugin ]]; then
            >&2 printf 'Plugin path "%s" is not a directory!\n' "$plugin"
            exit 1
          fi

          ${esc find} "$plugin" -name '*.tmux' | while read -r file; do
            printf "run '%s'\n" "$file" >> "$out"
          done
        done
      '';

  config = ''
    ${unlines pluginsSplit.pre}

    # Plugins loading {{{
    ${builtins.readFile pluginsLoadingCommandsFile}
    # Plugins loading }}}

    ${unlines pluginsSplit.post}
  '';

  configFile = writeTextFile {
    name = "tmux.conf";
    text = config;
    checkPhase = ''
      set -Eeuo pipefail || exit
      ${shellCheckers.fileIsExecutable tmuxsh-exe}
    '';
  };

  # ‘tmuxsh’ that is provided for the user for manual calls
  exported-tmuxsh = callPackage nix/apps/tmuxsh.nix {
    inherit __nix-utils;
    tmux-conf-file = configFile;
  };
in
wrapExecutable "${tmux}/bin/tmux" {
  deps = if with-tmuxsh then [ exported-tmuxsh ] else [];
  args = [ "-f" configFile ];
  checkPhase = ''
    ${
      if with-tmuxsh
      then shellCheckers.fileIsExecutable "${exported-tmuxsh}/bin/tmuxsh"
      else ""
    }
  '';
} // {
  inherit config configFile pluginsLoadingCommandsFile;
  tmuxsh = exported-tmuxsh;
}
