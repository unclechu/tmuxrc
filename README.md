# My tmux configuration

## Usage

### NixOS

#### Using it in NixOS `configuration.nix`

Here is an example of how it may look like in your `configuration.nix`:

``` nix
{ pkgs, ... }:
let
  tmuxConfig = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner  = "unclechu";
    repo   = "tmuxrc";
    rev    = "0000000000000000000000000000000000000000";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }) {};
in
{
  programs.tmux = {
    enable = true;
    extraConfig = tmuxConfig.config;
  };

  # This is optional. In case you need ‘tmuxsh’ script always available.
  environment.systemPackages = [
    tmux-config.tmuxsh
  ];
}
```

#### Run in a Nix Shell

``` sh
nix-shell --run tmux
```

### Other OS

1. Clone this repo somewhere, say to `~/.my-tmux-config`:

   ``` sh
   git clone --recursive https://github.com/unclechu/tmuxrc.git ~/.my-tmux-config
   ```

1. Create `~/.tmux/plugins` directory:

   ``` sh
   mkdir -p ~/.tmux/plugins
   ```

1. Create symlink `~/.tmux/plugins/tpm` pointing to [tpm] directory
   (Tmux Plugin Manager):

   ``` sh
   ln -s ~/.my-tmux-config/tpm ~/.tmux/plugins/tpm
   ```

1. Partially the configuration is provided by [apps/tmuxsh] script.
   Add it to your `PATH` environment variable (it could be `.local/bin` for
   instance, depends on your setup) but for this usage example we will manually
   override `PATH`. Just make sure that this runs successfully:

   ``` sh
   ~/.my-tmux-config/apps/tmuxsh help
   ```

1. Either create a symlink `~/.tmux.conf` that points to [.tmux.conf-v2.x] file:

   ``` sh
   ln -s ~/.my-tmux-config/.tmux.conf-v2.x ~/.tmux.conf
   ```

   Or if you want to be able to add some local changes to the config create new
   `~/.tmux.conf` file:

   ``` sh
   touch ~/.tmux.conf
   ```

   And include [.tmux.conf-v2.x] in that file and add some local changes:

   ``` tmux
   source ~/.my-tmux-config/.tmux.conf-v2.x
   set -g prefix ^B
   ```

1. Run `tmux` (`PATH` is overridden for `tmuxsh` script):

   ``` sh
   PATH=~/.my-tmux-config/apps:$PATH tmux
   ```

   And install the plugins by pressing `prefix` (`Ctrl` + `b` by default) + `I`
   (capital `i`, `Shift` + `i`)

## License

[Public Domain](LICENSE)

## Author

Viacheslav Lotsmanov

[.tmux.conf-v2.x]: .tmux.conf-v2.x
[apps/tmuxsh]: apps/tmuxsh
[tpm]: tpm
