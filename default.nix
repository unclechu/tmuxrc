let sources = import nix/sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
args@
{ callPackage
, writeTextFile
, lib
, dash
, findutils
, tmuxPlugins
, tmux

# Overridable dependencies
, __nix-utils ? callPackage sources.nix-utils {}

# Build options
, __srcConfigFile ? ./.tmux.conf-v2.x
# You can set this ‘__tmuxsh’ to ‘null’ if you don’t need this script
# but keep in mind that it’s a dependency for the tmux config itself.
, __tmuxsh ? callPackage nix/apps/tmuxsh.nix { inherit __nix-utils; }
}:
let
  inherit (__nix-utils)
    esc lines unlines writeCheckedExecutable wrapExecutable shellCheckers;

  tmuxsh = "${__tmuxsh}/bin/tmuxsh";

  replace-tmuxsh =
    if isNull __tmuxsh
    then x: x
    else builtins.replaceStrings [ "tmuxsh" ] [ tmuxsh ];

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

  pluginsLoader =
    let
      dash-exe = "${dash}/bin/dash";
      find = "${findutils}/bin/find";

      checkPhase = ''
        ${shellCheckers.fileIsExecutable dash-exe}
        ${shellCheckers.fileIsExecutable find}
        ${if isNull __tmuxsh then "" else shellCheckers.fileIsExecutable tmuxsh}
      '';

      plugins =
        builtins.map (x: handlePlugin tmuxPlugins.${x}) pluginsSplit.plugins;

      handlePlugin = p: ''
        ${find} ${esc p} -name '*.tmux' | while read -r file; do
          "$file" || exit
        done
      '';
    in
      writeCheckedExecutable "tmux-plugins-loader-script" checkPhase ''
        #! ${dash-exe}
        ${unlines plugins}
      '';

  config = ''
    ${unlines pluginsSplit.pre}
    run ${esc "${pluginsLoader}/bin/${pluginsLoader.name}"}
    ${unlines pluginsSplit.post}
  '';

  configFile = writeTextFile {
    name = "tmux.conf";
    text = config;
    checkPhase = ''
      set -Eeuo pipefail || exit
      ${if isNull __tmuxsh then "" else shellCheckers.fileIsExecutable tmuxsh}
    '';
  };
in
wrapExecutable "${tmux}/bin/tmux" {
  deps = if isNull __tmuxsh then [] else [ __tmuxsh ];
  args = [ "-f" configFile ];
} // {
  tmuxsh = __tmuxsh;
  inherit config configFile pluginsLoader;
}
