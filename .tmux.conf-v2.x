set -g escape-time 5
set -g mouse on
set -g renumber-windows on


set -g mode-keys vi
bind -t vi-copy 'v' begin-selection
bind -t vi-copy 'y' copy-selection

# moving windows
bind C-Left  swapw -t -1
bind C-Right swapw -t +1


set -g @plugin 'seebi/tmux-colors-solarized'
run '~/.tmux/plugins/tpm/tpm'


if "[[ \"$(tmux showenv _TMUX_COLORS | perl -pe 's/^[^=]+=//')\" != light ]]" " \
	set -g @colors-solarized 'dark' ; \
	set -g window-style 'bg=colour236,fg=colour187' ; \
	set -g window-active-style 'bg=colour235' \
"

if "[[ \"$(tmux showenv _TMUX_COLORS | perl -pe 's/^[^=]+=//')\" == light ]]" " \
	set -g @colors-solarized 'light' ; \
	set -g window-style 'bg=colour254,fg=colour235' ; \
	set -g window-active-style 'bg=colour15' \
"


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
set -g status-left-length 50
set -g status-right-length 40
set -g status-attr none
set -g status-fg colour137

if "[[ \"$(tmux showenv _TMUX_COLORS | perl -pe 's/^[^=]+=//')\" != light ]]" " \
	set -g status-bg colour234 ; \
	set -g status-left '#[fg=colour233,bg=colour245,bold] #{=-22:socket_path} #[bg=colour241] #{=-23:pane_current_path} #[bg=colour233] ' ; \
	set -g status-right '#[bg=colour234] #[fg=colour233,bg=colour241,bold] %d/%m #[bg=colour245] %H:%M:%S ' \
"

if "[[ \"$(tmux showenv _TMUX_COLORS | perl -pe 's/^[^=]+=//')\" == light ]]" " \
	set -g status-bg colour7 ; \
	set -g status-left '#[fg=colour254,bg=colour245,bold] #{=-22:socket_path} #[bg=colour241] #{=-23:pane_current_path} #[bg=colour7] ' ; \
	set -g status-right '#[bg=colour7] #[fg=colour254,bg=colour241,bold] %d/%m #[bg=colour245] %H:%M:%S ' \
"

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

if "[[ \"$(tmux showenv _TMUX_COLORS | perl -pe 's/^[^=]+=//')\" != light ]]" " \
	set -g message-fg colour233 ; \
	set -g message-bg colour245 ; \
	set -g message-command-fg colour7 ; \
	set -g message-command-bg colour241 \
"

if "[[ \"$(tmux showenv _TMUX_COLORS | perl -pe 's/^[^=]+=//')\" == light ]]" " \
	set -g message-fg colour7 ; \
	set -g message-bg colour241 ; \
	set -g message-command-fg colour233 ; \
	set -g message-command-bg colour245 \
"

# vim: ft=sh :
