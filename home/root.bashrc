# ~/.bashrc
# This file is sourced by all *interactive* bash shells on startup (as root)

# PS1 Prompt
export PS1="\[\e[38;5;9m\][\[\e[38;5;11m\]\u\[\e[38;5;2m\]@\[\e[38;5;12m\]\h \
\[\e[38;5;5m\]\w\[\e[38;5;9m\]]\[\e[0m\]# "

check_terminal_support() {
  local pid=$PPID
  local max_depth=5
  local depth=0
  local comm
  
  # Check process tree
  while [ $depth -lt $max_depth ] && [ "$pid" -gt 1 ]; do
    comm=$(ps -h -o comm -p "$pid" 2>/dev/null)
    if [[ $comm == *gnome-terminal* ]] || \
       [[ $comm == "gedit" ]] || \
       [[ $comm == "codium" ]] || \
       [[ $comm == *xfce4-terminal* ]]; then
      return 0  # Found supported terminal
    fi
    pid=$(ps -h -o ppid -p "$pid" 2>/dev/null | tr -d ' ')
    ((depth++))
  done
  return 1  # No supported terminal found
}

# Load Synth Shell Prompt only in specific terminals
if check_terminal_support; then
  if [ -f "$HOME/.config/synth-shell/synth-shell-prompt.sh" ] && \
    echo "$-" | grep -q i; then
    source "$HOME/.config/synth-shell/synth-shell-prompt.sh"
  fi
fi