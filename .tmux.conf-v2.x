set-option -g mouse on
set -gs escape-time 5

set-window-option -g mode-keys vi
bind-key -t vi-copy 'v' begin-selection
bind-key -t vi-copy 'y' copy-selection

set -g @plugin 'seebi/tmux-colors-solarized'

run '~/.tmux/plugins/tpm/tpm'
