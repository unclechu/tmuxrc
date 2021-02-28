let sources = import nix/sources.nix; in
args@
# Forwarded arguments
{ pkgs          ? import sources.nixpkgs {}
, utils         ? import sources.nix-utils { inherit pkgs; }
, srcConfigFile ? null
, tmuxsh        ? import nix/apps/tmuxsh.nix { inherit pkgs utils; }

# Local arguments
, with-tmux   ? true
, with-tmuxsh ? true
}:
let
  forwardedNames = [ "pkgs" "utils" "srcConfigFile" "tmuxsh" ];
  filterForwarded = pkgs.lib.filterAttrs (n: v: builtins.elem n forwardedNames);
  forwardedArgs = filterForwarded args;

  tmux = import ./. forwardedArgs;
in
pkgs.mkShell {
  buildInputs =
    (if with-tmux   then [ tmux ]   else []) ++
    (if with-tmuxsh then [ tmuxsh ] else []);
}
