# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import ../sources.nix; in
{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib
, callPackage ? pkgs.callPackage

, perl ? pkgs.perl
, perlPackages ? pkgs.perlPackages
, tmux ? pkgs.tmux

, executable-dependencies ? callPackage ../utils/executable-dependencies.nix {}
, mk-generic-script ? callPackage ../utils/mk-generic-script.nix {}

# ↓ Build options ↓

, __srcScript ? ../../apps/tmuxsh

# Needed for reloading tmux configuration (e.g. by ‘tmuxsh colors’).
# Set to ‘null’ to keep original ‘~/.tmux.conf’ value.
, tmux-conf-file
}:
let
  esc = lib.escapeShellArg;

  e = (executable-dependencies {
    perl = perl;
    tmux = tmux;
  }).extend (final: prev: {
    scriptDependencies =
      final.dependencies
        "^BEGIN [{] # Guard dependencies$"
        "^[[:space:]]*need_exe '([^']+)';([[:space:]]*#.*)?$";
  });

  perlDependencies = [
    perlPackages.IPCSystemSimple
  ];

  perlDependenciesBinPath = perlPackages.makePerlPath perlDependencies;

  name = "tmuxsh";

  src = lib.pipe __srcScript [
    (x:
      if isNull tmux-conf-file then x else let
        nextX =
          builtins.replaceStrings
            ["\"$HOME/.tmux.conf\""]
            ["q<${tmux-conf-file}>"]
            (builtins.readFile x);
      in
      assert nextX != x; # Something actually changed
      pkgs.writeText "${name}-source" nextX
    )
  ];

  pkg = mk-generic-script {
    inherit name src e;
    buildInputs = [ e.executables.perl ];
    lintBuildInputs = [ e.executables.perl ];
    wrapProgramArgs = [ "--set" "PERL5LIB" perlDependenciesBinPath ];

    checkPhase = ''
      ${lib.optionalString (! isNull tmux-conf-file) ''
        if ! [[ -f ${esc tmux-conf-file} && -r ${esc tmux-conf-file} ]]; then
          (set -o xtrace; [[ -f ${esc tmux-conf-file} && -r ${esc tmux-conf-file} ]])
        fi
      ''}
    '';

    cutOffRuntimeDependenciesCheckPhase = ''
      SED_CMD=(
        sed -i
        -e '/^BEGIN { # Guard dependencies/,/^}$/d'
        -e '/^use IPC::Cmd qw(can_run)/d'
        -e '/^sub need_exe/d'
        -- "$src"
      )
      "''${SED_CMD[@]}"
    '';

    lintPhase = ''
      (
        export PERL5LIB=${esc perlDependenciesBinPath}
        (
          export PATH=${esc (e.scriptDependenciesBinPath src)}:$PATH
          perl -c -- "$pre_patched_src"
        )
        perl -c -- "$src"
      )
    '';
  };
in

pkg // { inherit perlDependencies; }
