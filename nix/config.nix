let sources = import ./sources.nix; in
{ pkgs          ? import sources.nixpkgs {}
, utils         ? import sources.nix-utils { inherit pkgs; }
, srcConfigFile ? ../.tmux.conf-v2.x
, tmuxsh        ? import ./apps/tmuxsh.nix { inherit pkgs utils; }
}:
let
  inherit (utils) esc lines unlines writeCheckedExecutable wrapExecutable;

  pluginsSplit =
    let
      initial = { place = "pre"; pre = []; plugins = []; post = []; };

      result =
        builtins.foldl' reducer initial
          (lines (builtins.readFile srcConfigFile));

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
      pkgs.lib.filterAttrs (n: v: n != "place") result;

  pluginsLoader =
    let
      dash = "${pkgs.dash}/bin/dash";
      find = "${pkgs.findutils}/bin/find";

      checkPhase = ''
        ${utils.shellCheckers.fileIsExecutable dash}
        ${utils.shellCheckers.fileIsExecutable find}
      '';

      plugins =
        builtins.map
          (x: handlePlugin pkgs.tmuxPlugins.${x})
          pluginsSplit.plugins;

      handlePlugin = p: ''
        ${find} ${esc p} -name '*.tmux' | while read -r file; do
          "$file" || exit
        done
      '';
    in
      writeCheckedExecutable "tmux-plugins-loader-script" checkPhase ''
        #! ${dash}
        ${unlines plugins}
      '';

  config = ''
    ${unlines pluginsSplit.pre}
    run ${esc "${pluginsLoader}/bin/${pluginsLoader.name}"}
    ${unlines pluginsSplit.post}
  '';

  configFile = pkgs.writeText "tmux.conf" config;
in
{
  inherit config configFile pluginsLoader;

  # This can be imported in NixOS ‘configuration.nix’.
  systemConfiguration = {
    programs.tmux = {
      enable = true;
      extraConfig = config;
    };

    environment.systemPackages = [
      tmuxsh
    ];
  };
}
