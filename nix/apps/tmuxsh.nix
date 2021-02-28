let sources = import ../sources.nix; in
{ pkgs      ? import sources.nixpkgs {}
, utils     ? import sources.nix-utils { inherit pkgs; }
, srcScript ? ../../apps/tmuxsh
}:
let
  inherit (utils) writeCheckedExecutable wrapExecutableWithPerlDeps;
  perl = "${pkgs.perl}/bin/perl";

  script = writeCheckedExecutable "tmuxsh" ''
    ${utils.shellCheckers.fileIsExecutable perl}
  '' ''
    #! ${perl}
    ${builtins.readFile srcScript}
  '';
in
wrapExecutableWithPerlDeps "${script}/bin/${script.name}" {
  deps = p: [ p.IPCSystemSimple  ];
}
