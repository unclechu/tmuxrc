let sources = import nix/sources.nix; in
args@
{ pkgs          ? import sources.nixpkgs {}
, utils         ? import sources.nix-utils { inherit pkgs; }
, srcConfigFile ? null
, tmuxsh        ? import nix/apps/tmuxsh.nix { inherit pkgs utils; }
}:
let
  inherit (utils) wrapExecutable;
  inherit (import nix/config.nix args) configFile;
in
wrapExecutable "${pkgs.tmux}/bin/tmux" {
  deps = if isNull tmuxsh then [] else [ tmuxsh ];
  args = [ "-f" configFile ];
}
