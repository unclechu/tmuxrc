# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import ../sources.nix; in
{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib
, writeTextFile ? pkgs.writeTextFile

, bash ? pkgs.bash
, tmux ? pkgs.tmux
, xprop ? pkgs.xprop

# ↓ Build options ↓

, __srcScript ? ../../apps/tmux-report-current-pane-cwd
}:

let
  executables = {
    bash = bash;
    tmux = tmux;
    xprop = xprop;
  };

  esc = lib.escapeShellArg;
  bin = pkg: exe: "${pkg}/bin/${exe}";
  e = builtins.mapAttrs (n: v: esc (bin v n)) executables;
  executableFileCheck = x: "[[ -f ${x} || -r ${x} || -x ${x} ]]";
in

writeTextFile rec {
  name = "tmux-report-current-pane-cwd";
  executable = true;
  destination = "/bin/${name}";
  checkPhase = ''(
    set -o nounset
    ${builtins.concatStringsSep "\n" (map (x: ''
      if ! ${executableFileCheck x}; then (set -o xtrace && ${executableFileCheck x}); fi
    '') (builtins.attrValues e))}
  )'';
  text = ''
    #! ${let n = "bash"; in bin executables.${n} n}
    set -o errexit || exit

    export PATH=${
      esc (lib.makeBinPath (builtins.attrValues executables))
    }''${PATH:+:}''${PATH}

    ${builtins.readFile __srcScript}
  '';
}
