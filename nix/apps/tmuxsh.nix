# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import ../sources.nix; in
{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib
, perl ? pkgs.perl

# ↓ Build options ↓

, __srcScript ? ../../apps/tmuxsh

# Needed for reloading tmux configuration (e.g. by ‘tmuxsh colors’).
# Set to ‘null’ to keep original ‘~/.tmux.conf’ value.
, tmux-conf-file
}:
let
  esc = lib.escapeShellArg;
  perl-exe = "${perl}/bin/perl";

  script =
    assert ! isNull tmux-conf-file -> lib.isDerivation tmux-conf-file;
    let
      replaceTmuxConfPath =
        builtins.replaceStrings ["\"$HOME/.tmux.conf\""] ["q<${tmux-conf-file}>"];
      processScript =
        if isNull tmux-conf-file then lib.id else replaceTmuxConfPath;
    in
    pkgs.writeTextFile rec {
      name = "tmuxsh";
      executable = true;
      destination = "/bin/${name}";
      text = ''
        #! ${perl-exe}
        ${processScript (builtins.readFile __srcScript)}
      '';
      checkPhase = ''(
        set -o nounset
        set -o xtrace
        (f=${esc perl-exe}; [[ -f $f && -r $f && -x $f ]])

        ${lib.optionalString (! isNull tmux-conf-file) ''
          (f=${esc "${tmux-conf-file}"}; [[ -f $f && -r $f ]])
        ''}
      )'';
    };

  scriptWithPerlDeps = pkgs.symlinkJoin {
    name = "${lib.getName script}-wrapper";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    paths = [ script ];
    postBuild = ''
      wrapProgram "$out"/bin/${esc (lib.getName script)} \
        --set PERL5LIB ${esc (with pkgs.perlPackages; makePerlPath [ IPCSystemSimple ])}
    '';
  };
in
  scriptWithPerlDeps
