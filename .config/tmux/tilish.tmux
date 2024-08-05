# extracted from https://github.com/jabirali/tmux-tilish/blob/master/tilish.tmux#L82
bind='bind -n'
mod='M-'
shiftnum='!@#$%^&*()'
tilish_default='main-vertical'

bind_switch () {
	# Bind keys to switch between workspaces.
	tmux $bind "$1" \
		if-shell "tmux select-window -t :$2" "" "new-window -c '#{pane_current_path}' -t :$2"
		# if-shell "tmux select-window -t :$2" "" "new-window -c '#{session_start_path}' -t :$2"
}

bind_move () {
	# Bind keys to move panes between workspaces.
    tmux $bind "$1" \
        if-shell "tmux join-pane -t :$2" \
            "" \
            "new-window -dt :$2; join-pane -t :$2; select-pane -t top-left; kill-pane" \\\;\
        select-layout \\\;\
        select-layout -E
}


char_at () {
	# Finding the character at a given position in
	# a string in a way compatible with POSIX sh.
	echo $1 | cut -c $2
}

# Switch to workspace via Alt + #.
bind_switch "${mod}1" 1
bind_switch "${mod}2" 2
bind_switch "${mod}3" 3
bind_switch "${mod}4" 4
bind_switch "${mod}5" 5
bind_switch "${mod}6" 6
bind_switch "${mod}7" 7
bind_switch "${mod}8" 8
bind_switch "${mod}9" 9
bind_switch "${mod}0" 10

# Move pane to workspace via Alt + Shift + #.
bind_move "${mod}$(char_at $shiftnum 1)" 1
bind_move "${mod}$(char_at $shiftnum 2)" 2
bind_move "${mod}$(char_at $shiftnum 3)" 3
bind_move "${mod}$(char_at $shiftnum 4)" 4
bind_move "${mod}$(char_at $shiftnum 5)" 5
bind_move "${mod}$(char_at $shiftnum 6)" 6
bind_move "${mod}$(char_at $shiftnum 7)" 7
bind_move "${mod}$(char_at $shiftnum 8)" 8
bind_move "${mod}$(char_at $shiftnum 9)" 9
bind_move "${mod}$(char_at "$shiftnum" 10)" 10




# Autorefresh layout after deleting a pane.
tmux set-hook -g after-split-window "select-layout; select-layout -E"
tmux set-hook -g pane-exited "select-layout; select-layout -E"

# Autoselect layout after creating new window.
if [ -n "${tilish_default:-}" ]
then
    tmux set-hook -g window-linked "select-layout \"$tilish_default\"; select-layout -E"
    tmux select-layout "$tilish_default"
    tmux select-layout -E
fi

