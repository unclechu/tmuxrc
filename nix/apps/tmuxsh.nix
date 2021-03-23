let sources = import ../sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
{ callPackage
, perl

# Overridable dependencies
, __nix-utils ? callPackage sources.nix-utils {}

# Build options
, __srcScript ? ../../apps/tmuxsh
}:
let
  inherit (__nix-utils)
    writeCheckedExecutable wrapExecutableWithPerlDeps shellCheckers;

  perl-exe = "${perl}/bin/perl";

  script = writeCheckedExecutable "tmuxsh" ''
    ${shellCheckers.fileIsExecutable perl-exe}
  '' ''
    #! ${perl-exe}
    ${builtins.readFile __srcScript}
  '';
in
wrapExecutableWithPerlDeps "${script}/bin/${script.name}" {
  deps = p: [ p.IPCSystemSimple ];
}
