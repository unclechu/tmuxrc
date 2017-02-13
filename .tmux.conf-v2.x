set-option -g mouse on
set -gs escape-time 5

set-window-option -g mode-keys vi
bind-key -t vi-copy 'v' begin-selection
bind-key -t vi-copy 'y' copy-selection


# make active pane looks obvious
set -g window-style 'bg=#2e2e2e'
set -g window-active-style 'bg=#262626'
set -g pane-active-border-bg '#bf5705'


set -g @plugin 'seebi/tmux-colors-solarized'

run '~/.tmux/plugins/tpm/tpm'
