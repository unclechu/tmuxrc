set-option -g mouse on
set -gs escape-time 5

set-window-option -g mode-keys vi
bind-key -t vi-copy 'v' begin-selection
bind-key -t vi-copy 'y' copy-selection



set -g @plugin 'seebi/tmux-colors-solarized'


# Make it obvious which pane is active right now.
# Colors based on 'tmuxcolors-256.conf' from 'seebi/tmux-colors-solarized'.
set -g pane-border-bg colour244
set -g pane-active-border-bg colour166

# dark (by default)
if "[[ \"$_TMUX_COLOR\" != light ]]" " \
	setw -g window-style 'bg=colour236,fg=colour144' ; \
	setw -g window-active-style 'bg=colour235' ; \
	set -g @colors-solarized 'dark' \
"

if "[[ \"$_TMUX_COLOR\" == light ]]" " \
	setw -g window-style 'bg=colour254,fg=colour235' ; \
	setw -g window-active-style 'bg=colour15' ; \
	set -g @colors-solarized 'light' \
"

# status line
set -g status-justify left
set -g status-interval 2



# loud or quiet?
set-option -g visual-activity off
set-option -g visual-bell off
set-option -g visual-silence off
set-window-option -g monitor-activity off
set-option -g bell-action none

# modes
setw -g clock-mode-colour colour135
setw -g mode-attr bold
setw -g mode-fg colour196
setw -g mode-bg colour238


# statusbar

set -g status-position bottom
#set -g status-bg colour234
#set -g status-fg colour137
set -g status-attr dim
set -g status-left-length 40
set -g status-left '#[fg=colour233,bg=colour245,bold] #S '
set -g status-right-length 40
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '

setw -g window-status-current-fg colour1
setw -g window-status-current-bg colour238
setw -g window-status-current-attr bold
setw -g window-status-current-format ' #[fg=colour221]#I#[fg=colour250]:#[fg=colour255]#W#[fg=colour221]#F '

setw -g window-status-fg colour1
setw -g window-status-bg colour235
setw -g window-status-attr none
setw -g window-status-format ' #[fg=colour142]#I#[fg=colour243]:#[fg=colour250]#W#[fg=colour142]#F '

#setw -g window-status-bell-attr bold
#setw -g window-status-bell-fg colour255
#setw -g window-status-bell-bg colour1


# messages
set -g message-attr bold
#set -g message-fg colour233
#set -g message-bg colour241
set -g message-command-attr bold
set -g message-command-fg colour233
set -g message-command-bg colour245



run '~/.tmux/plugins/tpm/tpm'
