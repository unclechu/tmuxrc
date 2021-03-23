# Author: Viacheslav Lotsmanov
# License: Public Domain https://raw.githubusercontent.com/unclechu/tmuxrc/master/LICENSE

let sources = import nix/sources.nix; in
args@
{ pkgs ? import sources.nixpkgs {}

# Forwarded arguments
, __nix-utils ? pkgs.callPackage sources.nix-utils {}
, __srcConfigFile ? null
, __tmuxsh ? pkgs.callPackage nix/apps/tmuxsh.nix { inherit __nix-utils; }

# Local arguments
, with-tmux   ? true
, with-tmuxsh ? true
}:
let
  forwardedNames = [ "__nix-utils" "__srcConfigFile" "__tmuxsh" ];
  filterForwarded = pkgs.lib.filterAttrs (n: v: builtins.elem n forwardedNames);
  forwardedArgs = filterForwarded args;

  tmux = pkgs.callPackage ./. forwardedArgs;
in
pkgs.mkShell {
  buildInputs =
    (if with-tmux   then [ tmux ]     else []) ++
    (if with-tmuxsh then [ __tmuxsh ] else []);
}
