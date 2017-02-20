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

if "[[ \"$_TMUX_COLOR\" != light ]]" " \
	setw -g window-style 'bg=colour236,fg=colour248' ; \
	setw -g window-active-style 'bg=colour235' ; \
	set -g @colors-solarized 'dark' \
"

if "[[ \"$_TMUX_COLOR\" == light ]]" " \
	setw -g window-style 'bg=colour254,fg=colour0' ; \
	setw -g window-active-style 'bg=colour15' ; \
	set -g @colors-solarized 'light' \
"

# status line
# set -g status-utf8 on
set -g status-justify left
#set -g status-bg default
#set -g status-fg colour12
set -g status-interval 2

# messaging
set -g message-fg black
set -g message-bg yellow
set -g message-command-fg blue
set -g message-command-bg black

# window mode
setw -g mode-bg colour6
setw -g mode-fg colour0

# window status
setw -g window-status-format " #F#I:#W#F "
setw -g window-status-current-format " #F#I:#W#F "
setw -g window-status-format "#[fg=magenta]#[bg=black] #I #[bg=cyan]#[fg=colour8] #W "
setw -g window-status-current-format "#[bg=brightmagenta]#[fg=colour8] #I #[fg=colour8]#[bg=colour14] #W "
setw -g window-status-current-bg colour0
setw -g window-status-current-fg colour11
setw -g window-status-current-attr dim
setw -g window-status-bg green
setw -g window-status-fg black
setw -g window-status-attr reverse

# info on left
set -g status-left ''

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
set -g status-bg colour234
set -g status-fg colour137
set -g status-attr dim
set -g status-left ''
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20

setw -g window-status-current-fg colour81
setw -g window-status-current-bg colour238
setw -g window-status-current-attr bold
setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '

setw -g window-status-fg colour138
setw -g window-status-bg colour235
setw -g window-status-attr none
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

setw -g window-status-bell-attr bold
setw -g window-status-bell-fg colour255
setw -g window-status-bell-bg colour1


# messages
set -g message-attr bold
#set -g message-fg colour232
#set -g message-bg colour166



run '~/.tmux/plugins/tpm/tpm'
