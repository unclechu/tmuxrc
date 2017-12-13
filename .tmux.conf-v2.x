set -g escape-time 5
set -g mouse on
set -g renumber-windows on

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1


set -g mode-keys vi
bind -t vi-copy 'v' begin-selection
bind -t vi-copy 'y' copy-selection

# moving windows
bind C-Left  swapw -t -1
bind C-Right swapw -t +1


set -g @plugin 'seebi/tmux-colors-solarized'
run '~/.tmux/plugins/tpm/tpm'
if "[ -z \"`tmuxsh rc`\" ]" ''


# panes
set -g pane-border-bg colour244
set -g pane-border-fg colour252
set -g pane-active-border-bg colour166
set -g pane-active-border-fg colour222


# loud or quiet?
set -g visual-activity off
set -g visual-bell off
set -g visual-silence off
set -g bell-action none
set -g monitor-activity off


# modes
set -g clock-mode-colour colour135
set -g mode-attr bold
set -g mode-fg colour196
set -g mode-bg colour238


# statusbar

set -g status-interval 2
set -g status-justify left
set -g status-position bottom
set -g status-right-length 40
set -g status-attr none
set -g status-fg colour137

set -g window-status-fg colour1
set -g window-status-bg colour235
set -g window-status-attr none
set -g window-status-format ' #[fg=colour142]#I#[fg=colour243]:#[fg=colour250]#W#[fg=colour142]#F '

set -g window-status-current-fg colour1
set -g window-status-current-bg colour238
set -g window-status-current-attr bold
set -g window-status-current-format ' #[fg=colour221]#I#[fg=colour250]:#[fg=colour255]#W#[fg=colour221]#F '

set -g window-status-bell-attr bold
set -g window-status-bell-fg colour255
set -g window-status-bell-bg colour1


# messages

set -g message-attr bold
set -g message-command-attr bold


# vim: ft=sh :
