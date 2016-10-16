set -g mode-mouse on
set -g mouse-resize-pane on
set -g mouse-select-pane on
set -g mouse-select-window on

set-window-option -g mode-keys vi
bind-key -t vi-copy 'v' begin-selection
bind-key -t vi-copy 'y' copy-selection

set -g @plugin 'seebi/tmux-colors-solarized'

run '~/.tmux/plugins/tpm/tpm'
