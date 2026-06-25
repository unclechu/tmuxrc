# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import ../sources.nix; in
{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib
, callPackage ? pkgs.callPackage

, bash ? pkgs.bash
, tmux ? pkgs.tmux
, xprop ? pkgs.xprop

, executable-dependencies ? callPackage ../utils/executable-dependencies.nix {}
, mk-generic-script ? callPackage ../utils/mk-generic-script.nix {}

# ↓ Build options ↓

, __srcScript ? ../../apps/tmux-report-current-pane-cwd
}:

let
  e = (executable-dependencies {
    tmux = tmux;
    xprop = xprop;
  }).extend (final: prev: {
    scriptDependenciesBinPath =
      lib.flip final.scriptDependenciesBinPathWithIgnore [ ''"$TMUX_EXE"'' ];
  });
in

mk-generic-script {
  name = "tmux-report-current-pane-cwd";
  src = __srcScript;
  inherit e;
  wrapProgramArgs = [
    # The script allows to customize `TMUX_EXE`, the dependency is not
    # typical, thus does not propagate automatically. Adding manually.
    "--prefix" "PATH" ":" (lib.makeBinPath [ e.executables.tmux ])
  ];
}
