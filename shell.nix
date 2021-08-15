# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import nix/sources.nix; in
args@
{ pkgs ? import sources.nixpkgs {}

# Forwarded arguments
, __nix-utils ? pkgs.callPackage sources.nix-utils {}
, __srcConfigFile ? null

# Local arguments
, with-tmux   ? true
, with-tmuxsh ? true
}:
let
  forwardedNames = [ "__nix-utils" "__srcConfigFile" ];
  filterForwarded = pkgs.lib.filterAttrs (n: v: builtins.elem n forwardedNames);
  forwardedArgs = filterForwarded args;

  tmux = pkgs.callPackage ./. forwardedArgs;
  inherit (tmux) tmuxsh;
in
pkgs.mkShell {
  buildInputs =
    pkgs.lib.optional with-tmux tmux ++
    pkgs.lib.optional with-tmuxsh tmuxsh;
}
