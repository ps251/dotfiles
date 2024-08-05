# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export FPATH=/home/peter/.local/share/zsh/site-functions/:$FPATH


setopt histignorealldups sharehistory

bindkey -v

HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history


autoload -Uz compinit
# https://lobste.rs/s/xcmf7e/speeding_up_zsh_startup
if [[ -n $(print ~/.zcompdump(Nmh+24)) ]] {
  compinit
} else {
  compinit -C
}



zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
# zstyle ":completion:*" list-dirs-first

# https://thevaluable.dev/zsh-completion-guide-examples/
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"



alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'


alias alert='notify-send -u "normal" -t "2000" -c mine -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


alias v="nvim"
alias vim="nvim"
alias e="/home/peter/bin/emacsclient_terminal_frame.sh"
alias c="cheat -e"
alias x="xdg-open"
alias ex="/home/peter/bin/emacsclient_gui_frame.sh"

alias vl="NVIM_APPNAME=LazyVim nvim"
alias vn="NVIM_APPNAME=nvim-new nvim"

# sudo with aliases 
# https://unix.stackexchange.com/questions/363462/how-can-i-get-sudo-commands-to-use-the-settings-in-root-bashrc/458632
alias sudo='sudo '


alias fz="fzf --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} &>/dev/null || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || identify {} &>/dev/null && fzf-preview.sh {} || echo {} 2> /dev/null | head -200'"


# [[id:9f96a628-7b3f-4679-97a2-4114068863a8][git bare repo for dot files]]
alias config_raw='/usr/bin/git --git-dir=/home/peter/Notes/roam/projects/dot_files/raw/ --work-tree=/home/peter'
alias config='/usr/bin/git --git-dir=/home/peter/Notes/roam/projects/dot_files/cfg/ --work-tree=/home/peter'


# Set up fzf key bindings and fuzzy completion here
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"



human_path() {
  sed "s#^$HOME#~#g"
}

expand_tilde() {
  sed "s#^~#$HOME#g"
}

relative_path() {
  sed "s#$PWD/##g"
}

quick_paths() {
  # fd -aH -d4 "" /home/peter/Notes/roam/projects/
  # fd -H -d4 .
  fd -t f -d3 -H .

  grep -oP "\"\K[^\"]+(?=\")" "/home/peter/.emacs.d/.local/cache/recentf"

  [ -f /tmp/vimoldfiles ] || touch /tmp/vimoldfiles 
  vim -c "redir! > /tmp/vimoldfiles" -c "silent oldfiles" -c "redir END" -c 'qa!' | cat /tmp/vimoldfiles | cut -d ' ' -s -f 2- 
}

quick_directory_paths() {
  { fd -t d -d3 -H .; zoxide query --list; fd -t d -d6 -H . ~ }
}

append_history() {
  "$@"
  print -s -- "$*"
}

go_to_parent() {
  z ..
  zle accept-line
  ls
  zle accept-line
}
zle -N go-to-parent go_to_parent

go_to_home() {
  cd
  zle accept-line
}
zle -N go-to-home go_to_home

ps_clear() {
  clear
  zle reset-prompt
}
zle -N ps-clear ps_clear

ps_ls() {
  ls
  zle accept-line
}
zle -N ps-ls ps_ls


fzf_directory_paths() {
  local word="${LBUFFER##* }"

  local selected
  selected="$($@ | relative_path | human_path | awk '!seen[$0]++' | fz --print-query --height=70% --query="$word" --select-1 --bind 'ctrl-x:change-prompt(System Directories> )+reload(fd -t d -d12 --exclude /home* . /)' --header="Use CTRL-x for system" | expand_tilde)"
  if [[ "$selected" ]]; then
    local lines=( ${(f)selected} )
    if (( ${#lines[@]} == 1 )); then
      selected="${lines[1]}"
    else
      selected="${lines[2]}"
    fi

    if [[ ! "$BUFFER" ]]; then
      if [[ -d "$selected" ]]; then
        append_history z "$selected"
      elif [[ -e "$selected" ]]; then
        append_history z `dirname "$selected"`
      else
        mkdir -p "$selected"
        append_history z "$selected"
        zle accept-line # necessary for update
      fi
      ls
      zle accept-line
    else
      LBUFFER="${LBUFFER%$word}${selected}"
      zle reset-prompt
    fi
  fi
  # tree -C -L 1 | head -n 50
}
fzf_quick_directory_paths() {
  fzf_directory_paths quick_directory_paths
}
fzf_child_directory_paths() {
  fzf_directory_paths fd --exact-depth 1 -t d -H
}
# Goes into parent directory when matching file
fzf_descendant_paths() {
  fzf_directory_paths fd --max-depth 4 -H
}
zle -N fzf-quick-directory-paths fzf_quick_directory_paths
zle -N fzf-child-directory-paths fzf_child_directory_paths
zle -N fzf-descendant-paths fzf_descendant_paths

fzf_paths() {
  local word="${LBUFFER##* }"

  local selected
  selected="$($@ | relative_path | human_path | awk '!seen[$0]++' | fz --print-query --no-sort --height=70% --query="$word" --bind='ctrl-x:reload(locate_local)' --bind='ctrl-w:reload(locate "")' --header="Use CTRL-x for locate-local, CTRL-w for locate" | expand_tilde)"
  if [[ "$selected" ]]; then
    local lines=( ${(f)selected} )
    if (( ${#lines[@]} == 1 )); then
      selected="${lines[1]}"
    else
      selected="${lines[2]}"
    fi
    if [[ ! "$BUFFER" ]]; then
      if [[ -d "$selected" ]]; then
        append_history z "$selected"
      elif [[ -e "$selected" ]]; then
        append_history "$EDITOR" "$selected"
      else
        if [[ -n `dirname "$selected"` ]]; then
          local dir=`dirname "$selected"`
          mkdir -p "$dir"
          append_history z "$dir"
        fi
        append_history "$EDITOR" `basename "$selected"`
      fi
      zle accept-line
    else
      LBUFFER="${LBUFFER%$word}${selected} "
      zle reset-prompt
    fi
  fi
}
fzf_quick_paths () {
  fzf_paths quick_paths
}
fzf_open_child () {
  fzf_paths fd --exact-depth 1 -t f -H
}
fzf_open_descendant () {
  fzf_paths fd -t f --max-depth 5 -H
}
zle -N fzf-quick-paths fzf_quick_paths
zle -N fzf-open-child fzf_open_child
zle -N fzf-open-descendant fzf_open_descendant


fzf_commands() {
  local word="${LBUFFER##* }"
  local selected
  IFS=$'\n'   selected=($($@ | fzf --no-sort --height=40% --query="$word" ))
  if [[ ! "$BUFFER" ]]; then
    if [[ "$selected" ]]; then
      LBUFFER="$selected"
      if [[ ${#selected[@]} -eq 2 ]]; then
        LBUFFER="${selected[2]}"
      fi
      zle accept-line
    fi
  else
    LBUFFER="${LBUFFER%$word}${selected} "
    zle reset-prompt
  fi
  zle reset-prompt
}
fzf_history() {
  fzf_commands fc -lnr 1 
}
all_commands() {
  echo "$PATH" | tr ":" "\n" | xargs -I{} -- find {} -maxdepth 1 -mindepth 1 -executable 2>/dev/null | sort -u 
}
fzf_all_commands() {
  fzf_commands all_commands
}
zle -N fzf-history fzf_history
zle -N fzf-all-commands fzf_all_commands



# General Keybindings
bindkey '\em' accept-line

bindkey "^R" fzf-history
bindkey "ⓙ" fzf-quick-paths
bindkey "ⓚ" fzf-quick-directory-paths
bindkey "ⓛ" fzf-child-directory-paths
bindkey "Ⓛ" fzf-descendant-paths
bindkey "ṣ" fzf-open-child
bindkey "ṡ" fzf-open-descendant
bindkey "ⓞ" fzf-all-commands
bindkey 'ⓘ' ps-ls
bindkey 'ⓤ' ps-clear
bindkey 'Ⓗ' go-to-home
bindkey 'ⓗ' go-to-parent
bindkey 'Ⓙ' down-line-or-search
bindkey 'Ⓚ' up-line-or-search


# plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^[ ' autosuggest-execute
bindkey '^[f' forward-word    # for partial accept
bindkey '^f' forward-word    # for partial accept
bindkey '^u' autosuggest-toggle
bindkey '^L' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search
# :MY_ANKI_ID: 1710617283289


# Changed some bindings in source because lazy rebind; also to support system clipboard
source $HOME/.zsh/.zsh-vi-mode/zsh-vi-mode.plugin.zsh
export ZVM_VI_INSERT_ESCAPE_BINDKEY=jk


source ~/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
