set -g escape-time 5
set -g mouse on
set -g renumber-windows on

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1


set -g mode-keys vi
bind -T copy-mode-vi 'v' send -X begin-selection
bind -T copy-mode-vi 'y' send -X copy-selection

# moving windows
bind C-Left  swapw -t -1
bind C-Right swapw -t +1


set -g @plugin 'seebi/tmux-colors-solarized'
run '~/.tmux/plugins/tpm/tpm'
if "[ -z \"`tmuxsh rc`\" ]" ''


# panes
set -g pane-border-style bg=colour244,fg=colour252
set -g pane-active-border-style bg=colour166,fg=colour222


# loud or quiet?
set -g visual-activity off
set -g visual-bell off
set -g visual-silence off
set -g bell-action none
set -g monitor-activity off


# modes
set -g clock-mode-colour colour135
set -g mode-style bg=colour238,fg=colour196,bold


# statusbar

set -g status-interval 2
set -g status-justify left
set -g status-position bottom
set -g status-right-length 40
set -g status-style fg=colour137,none

set -g window-status-style bg=colour235,fg=colour1,none
set -g window-status-format ' #[fg=colour142]#I#[fg=colour243]:#[fg=colour250]#W#[fg=colour142]#F '

set -g window-status-current-style bg=colour238,fg=colour1,bold
set -g window-status-current-format ' #[fg=colour221]#I#[fg=colour250]:#[fg=colour255]#W#[fg=colour221]#F '

set -g window-status-bell-style bg=colour1,fg=colour255,bold


# messages

set -g message-style bold
set -g message-command-style bold


# vim: ft=sh :
