# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import ../sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
{ callPackage
, lib
, perl

# Overridable dependencies
, __nix-utils ? callPackage sources.nix-utils {}

# ↓ Build options ↓

, __srcScript ? ../../apps/tmuxsh

# Needed for reloading tmux configuration (e.g. by ‘tmuxsh colors’).
# Set to ‘null’ to keep original ‘~/.tmux.conf’ value.
, tmux-conf-file
}:
let
  inherit (__nix-utils)
    writeCheckedExecutable wrapExecutableWithPerlDeps shellCheckers;

  perl-exe = "${perl}/bin/perl";

  script =
    assert ! isNull tmux-conf-file -> lib.isDerivation tmux-conf-file;
    writeCheckedExecutable "tmuxsh" ''
      ${shellCheckers.fileIsExecutable perl-exe}
      ${
        if isNull tmux-conf-file then "" else
        shellCheckers.fileIsReadable (toString tmux-conf-file)
      }
    '' ''
      #! ${perl-exe}
      ${
        (
          if isNull tmux-conf-file
          then x: x
          else builtins.replaceStrings
                 ["\"$HOME/.tmux.conf\""]
                 ["q<${tmux-conf-file}>"]
        )
          (builtins.readFile __srcScript)
      }
    '';
in
wrapExecutableWithPerlDeps "${script}/bin/${script.name}" {
  deps = p: [ p.IPCSystemSimple ];
}
