# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import nix/sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib
, callPackage ? pkgs.callPackage

, tmux ? pkgs.tmux
, tmuxPlugins ? pkgs.tmuxPlugins
, findutils ? pkgs.findutils

, inNixShell ? false

, executable-dependencies ? callPackage nix/utils/executable-dependencies.nix {}
, mk-generic-script ? callPackage nix/utils/mk-generic-script.nix {}

# ↓ Build options ↓

, __srcConfigFile ? ./.tmux.conf

# Make ‘tmuxsh’ available for calling it manually (inside ‘tmux’ session).
# This is not necessary if you add ‘tmuxsh’ to ‘environment.systemPackages’ in
# your NixOS ‘configuration.nix’ for instance. Also this is for executable
# version only, in ‘configuration.nix’ you set just tmux config file
# (to ‘programs.tmux.extraConfig’) and this dependency wouldn’t be provided
# anyway if you don’t add it to ‘environment.systemPackages’.
, with-tmuxsh ? inNixShell

, with-tmux-report-current-pane-cwd ? inNixShell

, with-tmux ? inNixShell
}:

let
  esc = lib.escapeShellArg;

  # ‘tmuxsh’ for the tmux config itself, without ‘tmux-conf-file’ argument.
  # Otherwise it would be a recursive dependency.
  # ‘tmuxsh rc’ that tmux config is calling doesn’t depend on that argument.
  tmuxsh = pkgs.callPackage nix/apps/tmuxsh.nix {
    tmux-conf-file = null;
  };

  tmux-report-current-pane-cwd =
    pkgs.callPackage nix/apps/tmux-report-current-pane-cwd.nix {};

  executablesMap = {
    tmux = tmux;
    tmuxsh = tmuxsh;
    tmux-report-current-pane-cwd = tmux-report-current-pane-cwd;
    find = findutils;
  };

  e = executable-dependencies executablesMap;

  # Type: string → string
  replace-tmuxsh = builtins.replaceStrings [ "tmuxsh" ] [ e.b.tmuxsh ];

  # Type: string → string
  replace-tmux-report-current-pane-cwd =
    builtins.replaceStrings
      [ "tmux-report-current-pane-cwd" ]
      [ e.b.tmux-report-current-pane-cwd ];

  # Type: {
  #   pre = [string]; # Config part before plugins section
  #   plugins = [string]; # A list of extracted plugin names
  #   post = [string]; # Config part after plugins section
  # }
  pluginsSplit =
    let
      initial = { place = "pre"; pre = []; plugins = []; post = []; };

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
                      else { plugins = acc.plugins ++ [ (builtins.elemAt match 0) ]; }
        else

        if acc.place == "post"
        then { post = acc.post ++ [line]; }
        else throw "Unexpected ‘place’ during parsing: ‘${acc.place}’"
      );
    in
      lib.pipe __srcConfigFile [
        builtins.readFile
        replace-tmuxsh
        replace-tmux-report-current-pane-cwd
        # Keep the context
        (x: { c = builtins.getContext x; v = x; })
        (x: x // { v = builtins.split "\n" x.v; })
        (x: x // { v = builtins.filter builtins.isString x.v; })
        (x: x // { v = builtins.foldl' reducer initial x.v; })
        (x: assert x.v.place == "post"; x)
        (x: {
          # Restore the context that is lost after `builtins.split`
          pre = map (lib.flip builtins.appendContext x.c) x.v.pre;
          post = map (lib.flip builtins.appendContext x.c) x.v.post;
          inherit (x.v) plugins;
        })
      ];

  # Type: [derivation]
  plugins = builtins.map (x: tmuxPlugins.${x}) pluginsSplit.plugins;

  config = ''
    ${builtins.concatStringsSep "\n" pluginsSplit.pre}
    # Plugins loading {{{
    ${builtins.concatStringsSep "\n" (map (plugin: "run '${plugin.rtp}'") plugins)}
    # Plugins loading }}}
    ${builtins.concatStringsSep "\n" pluginsSplit.post}
  '';

  configFile = pkgs.writeTextFile {
    name = "tmux.conf";
    text = config;
    checkPhase = ''(
      set -o errexit || exit; set -o errtrace; set -o nounset; set -o pipefail

      ${e.checkPhase}

      # Checking that plugins are healthy
      (${
        builtins.concatStringsSep "\n" (map (plugin: ''
          if ! [[ -d ${esc "${plugin}"} ]]; then
            >&2 printf 'Plugin path "%s" is not a directory!\n' ${esc "${plugin}"}
            exit 1
          elif ! [[ -f ${esc "${plugin.rtp}"} ]]; then
            >&2 printf 'Plugin’s “rtp” value “%s” is not a file!\n' ${esc "${plugin.rtp}"}
            exit 1
          fi
        '') plugins)
      })
    )'';
  };

  eFinal = executable-dependencies (executablesMap // {
    # ‘tmuxsh’ that is provided for the user for manual calls
    tmuxsh = pkgs.callPackage nix/apps/tmuxsh.nix {
      tmux-conf-file = configFile;
    };
  });

  smokeTest = ''(
    set -o errexit || exit; set -o errtrace; set -o nounset; set -o pipefail

    smoke_dir="$(mktemp -d)"
    socket="$smoke_dir/tmux.sock"
    export HOME="$smoke_dir/home"
    export TMPDIR="$smoke_dir/tmp"
    mkdir -p -- "$HOME" "$TMPDIR"

    # Cleanup background tmux session
    cleanup() {
      "$bin" -S "$socket" kill-server &>/dev/null || true
      rm -rf -- "$smoke_dir"
    }
    trap cleanup EXIT

    "$bin" -S "$socket" new-session -d -s smoke 'sleep 30s'
    "$bin" -S "$socket" has-session -t smoke

    actual="$(
      "$bin" -S "$socket" display-message -p -t smoke \
        '#{session_name}:#{pane_current_command}'
    )"

    expected='smoke:sleep'

    if [[ "$actual" != "$expected" ]]; then
      >&2 printf 'tmux smoke test failed!\n'
      >&2 printf 'Expected “%s” while got: “%s”\n' "$expected" "$actual"
      exit 1
    fi

    "$bin" -S "$socket" kill-server
  )'';

  runtimeDeps =
    lib.optional with-tmuxsh eFinal.executables.tmuxsh
    ++
    lib.optional
      with-tmux-report-current-pane-cwd
      eFinal.executables.tmux-report-current-pane-cwd
    ;

  wenzels-tmux = pkgs.symlinkJoin rec {
    name = "wenzels-tmux";
    meta.mainProgram = baseNameOf eFinal.b.tmux;
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    paths = [ e.executables.tmux ];

    postBuild = ''
      ${eFinal.checkPhase}
      if ! [[ -f ${esc configFile} && -r ${esc configFile} ]]; then
        (set -o xtrace; [[ -f ${esc configFile} && -r ${esc configFile} ]])
      fi

      bin="$out"/bin/${esc meta.mainProgram}

      CMD=(
        wrapProgram "$bin"
        ${if builtins.length runtimeDeps <= 0 then "" else ''
          --prefix PATH : ${esc (lib.makeBinPath runtimeDeps)}
        ''}
        --add-flags ${esc "-f ${configFile}"}
      )
      "''${CMD[@]}"

      >/dev/null type -- "$bin"
      ${smokeTest}
    '';
  };

  shell = pkgs.stdenv.mkDerivation rec {
    name = "${lib.getName wenzels-tmux}-shell";
    dontUnpack = true; # Make it buildable without “src” attribute

    buildInputs =
      lib.optional with-tmux wenzels-tmux
      ++ lib.optional with-tmuxsh eFinal.executables.tmuxsh
      ++ lib.optional with-tmuxsh eFinal.executables.tmux-report-current-pane-cwd;

    installPhase = ''(
      set -o nounset
      touch -- "$out"
      printf '%s\n' ${lib.escapeShellArgs (map (x: "${x}") buildInputs)} >> "$out"
    )'';
  };
in

(if inNixShell then shell else {}) // {
  inherit config configFile shell;
  tmux = wenzels-tmux;
  tmuxsh = eFinal.executables.tmuxsh;
  tmux-report-current-pane-cwd =
    eFinal.executables.tmux-report-current-pane-cwd;
}
