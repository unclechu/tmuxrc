set-option -g mouse on
set -gs escape-time 5

set-window-option -g mode-keys vi
bind-key -t vi-copy 'v' begin-selection
bind-key -t vi-copy 'y' copy-selection


# Make it obvious which pane is active right now.
# Colors based on 'tmuxcolors-256.conf' from 'seebi/tmux-colors-solarized'.
set -g window-style 'bg=colour236'
set -g window-active-style 'bg=colour235'
set -g pane-border-bg colour244
set -g pane-active-border-bg colour166


set -g @plugin 'seebi/tmux-colors-solarized'

run '~/.tmux/plugins/tpm/tpm'
