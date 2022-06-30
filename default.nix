# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import nix/sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib

# Overridable dependencies
, __nix-utils ? pkgs.callPackage sources.nix-utils {}

, inNixShell ? false

# ↓ Build options ↓

, __srcConfigFile ? ./.tmux.conf

# Make ‘tmuxsh’ available for calling it manually (inside ‘tmux’ session).
# This is not necessary if you add ‘tmuxsh’ to ‘environment.systemPackages’ in
# your NixOS ‘configuration.nix’ for instance. Also this is for executable
# version only, in ‘configuration.nix’ you set just tmux config file
# (to ‘programs.tmux.extraConfig’) and this dependency wouldn’t be provided
# anyway if you don’t add it to ‘environment.systemPackages’.
, with-tmuxsh ? inNixShell

, with-tmux ? inNixShell
}:
let
  esc = lib.escapeShellArg;
  dash-exe = "${pkgs.dash}/bin/dash";
  tmux-exe = "${pkgs.tmux}/bin/tmux";

  inherit (__nix-utils) lines unlines;

  # ‘tmuxsh’ for the tmux config itself, without ‘tmux-conf-file’ argument.
  # Otherwise it would be a recursive dependency.
  # ‘tmuxsh rc’ that tmux config is calling doesn’t depend on that argument.
  tmuxsh = pkgs.callPackage nix/apps/tmuxsh.nix {
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
      find = "${pkgs.findutils}/bin/find";

      plugins = builtins.concatStringsSep "\n" (
        builtins.map (x: pkgs.tmuxPlugins.${x}) pluginsSplit.plugins
      );
    in
      pkgs.runCommand "tmux-plugin-imports" {
        inherit plugins;
        passAsFile = [ "plugins" ];
      } ''
        set -o errexit || exit
        set -o nounset
        set -o pipefail
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

  configFile = pkgs.writeTextFile {
    name = "tmux.conf";
    text = config;
    checkPhase = ''(
      set -o nounset
      set -o xtrace
      (f=${esc tmuxsh-exe}; [[ -f $f && -r $f && -x $f ]])
    )'';
  };

  # ‘tmuxsh’ that is provided for the user for manual calls
  exported-tmuxsh = pkgs.callPackage nix/apps/tmuxsh.nix {
    inherit __nix-utils;
    tmux-conf-file = configFile;
  };

  wenzels-tmux = pkgs.writeTextFile rec {
    name = "wenzels-tmux";
    executable = true;
    destination = "/bin/tmux";
    text = ''
      #! ${dash-exe}
      ${
        lib.optionalString
          with-tmuxsh
          "PATH=${esc (lib.makeBinPath [ exported-tmuxsh ])}\${PATH:+:}\${PATH:-} "
      }exec ${esc tmux-exe} -f ${esc configFile} "$@"
    '';
    checkPhase = ''(
      set -o nounset
      set -o xtrace
      (f=${esc dash-exe}; [[ -f $f && -r $f && -x $f ]])
      (f=${esc tmux-exe}; [[ -f $f && -r $f && -x $f ]])
      ${lib.optionalString with-tmuxsh ''
        (f=${esc "${exported-tmuxsh}/bin/tmuxsh"}; [[ -f $f && -r $f && -x $f ]])
      ''}
      (f=${esc configFile}; [[ -f $f && -r $f ]])
    )'';
  };

  shell = pkgs.stdenv.mkDerivation rec {
    name = "${lib.getName wenzels-tmux}-shell";
    dontUnpack = true; # Make it buildable without “src” attribute

    buildInputs =
      lib.optional with-tmux wenzels-tmux
      ++ lib.optional with-tmuxsh exported-tmuxsh;

    installPhase = ''(
      set -o nounset
      touch -- "$out"
      printf '%s\n' ${pkgs.lib.escapeShellArgs (map (x: "${x}") buildInputs)} >> "$out"
    )'';
  };
in
(if inNixShell then shell else {}) // {
  inherit config configFile pluginsLoadingCommandsFile shell;
  tmux = wenzels-tmux;
  tmuxsh = exported-tmuxsh;
}
