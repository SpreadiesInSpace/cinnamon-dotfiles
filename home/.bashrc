# ~/.bashrc
# This file is sourced by all *interactive* bash shells on startup

# If not running interactively, don't do anything
if [[ $- != *i* ]] ; then
	return
fi

# Source global definitions if they exist
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
	. /etc/bash.bashrc
fi

# Add local bins to user PATH if not already present
if ! [[ "$PATH" =~ $HOME/.local/bin:$HOME/bin: ]]; then
	PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# History configuration
HISTCONTROL=ignoreboth  # Ignore duplicates and lines starting with space
HISTSIZE=1000           # Commands in memory
HISTFILESIZE=2000       # Commands in history file

# Shell options
shopt -s histappend     # Append to history file, don't overwrite
shopt -s checkwinsize   # Update LINES and COLUMNS after each command
# shopt -s cdspell      # Auto-correct minor spelling errors in cd commands
# shopt -s dotglob      # Include .files when globbing
# shopt -s extglob      # Use extra globbing features
# shopt -s globstar     # Allow ** for recursive directory matching
# shopt -s nullglob     # Expand unmatched globs to nothing instead of literal
# shopt -o noclobber    # Prevent output redirection from overwriting files

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
	if test -r ~/.dircolors; then
		eval "$(dircolors -b ~/.dircolors)"
	else
		eval "$(dircolors -b)"
	fi
	alias ls='ls --color=auto'
	alias grep='grep --color=auto'
elif command -v ls >/dev/null 2>&1; then
	# Fallback for systems without dircolors
	alias ls='ls --color=auto' 2>/dev/null || alias ls='ls'
	alias grep='grep --color=auto' 2>/dev/null || alias grep='grep'
fi

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:'
export GCC_COLORS="${GCC_COLORS}locus=01:quote=01"

# Source distro-specific and common configuration files
if [ -d ~/.bashrc.d ]; then
	distro=""
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case "$ID" in
			arch) distro="arch" ;;
			fedora) distro="fedora" ;;
			gentoo) distro="gentoo" ;;
			linuxmint) distro="lmde" ;;
			nixos) distro="nixos" ;;
			opensuse*) distro="opensuse" ;;
			slackware) distro="slackware" ;;
			void) distro="void" ;;
		esac
	fi

	# Source the distro-specific script
	if [ -n "$distro" ] && [ -f "$HOME/.bashrc.d/${distro}.sh" ]; then
		. "$HOME/.bashrc.d/${distro}.sh"
	fi

	# Source remaining common scripts
	for rc in ~/.bashrc.d/*.sh; do
		case "$(basename "$rc")" in
			arch.sh|fedora.sh|gentoo.sh|lmde.sh|nixos.sh| \
			opensuse.sh|slackware.sh|void.sh)
				continue ;;
		esac
		[ -f "$rc" ] && . "$rc"
	done
fi

# Source alias files if they exist
for alias_file in ~/.bash_aliases ~/.alias; do
	if [ -f "$alias_file" ]; then
		. "$alias_file"
	fi
done

# Make less more friendly for non-text files
if [ -x /usr/bin/lesspipe ] && [ "$distro" != "gentoo" ]; then
	eval "$(SHELL=/bin/sh lesspipe)"
fi

# Enable programmable completion features (skip if in strict POSIX mode)
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

# Do sudo, or sudo the last command if no argument given
s() {
	if [[ $# == 0 ]]; then
		sudo "$(history -p '!!')"
	else
		sudo "$@"
	fi
}

# Extract files. Ignore files with improper extensions.
extract () {
	local x
	ee() { # Echo and execute
		echo "Extracting with: $*"
		if "$@"; then
			echo "Successfully extracted"
		else
			echo "Failed to extract $2" >&2
			return 1
		fi
	}
	for x in "$@"; do
		[[ -f $x ]] || { echo "File not found: $x" >&2; continue; }
		case "$x" in
			*.tar.bz2 | *.tbz2 )
				command -v tar >/dev/null || \
					{ echo "tar not found" >&2; continue; }
				ee tar xvjf "$x" ;;
			*.tar.gz | *.tgz )
				command -v tar >/dev/null || \
					{ echo "tar not found" >&2; continue; }
				ee tar xvzf "$x" ;;
			*.tar.xz | *.txz )
				command -v tar >/dev/null || \
					{ echo "tar not found" >&2; continue; }
				ee tar xvJf "$x" ;;
			*.bz2 )
				command -v bunzip2 >/dev/null || \
					{ echo "bunzip2 not found" >&2; continue; }
				ee bunzip2 "$x" ;;
			*.xz )
				command -v unxz >/dev/null || \
					{ echo "unxz not found" >&2; continue; }
				ee unxz "$x" ;;
			*.rar )
				command -v unrar >/dev/null || \
					{ echo "unrar not found" >&2; continue; }
				ee unrar x "$x" ;;
			*.gz )
				command -v gunzip >/dev/null || \
					{ echo "gunzip not found" >&2; continue; }
				ee gunzip "$x" ;;
			*.tar )
				command -v tar >/dev/null || \
					{ echo "tar not found" >&2; continue; }
				ee tar xvf "$x" ;;
			*.zip )
				command -v unzip >/dev/null || \
					{ echo "unzip not found" >&2; continue; }
				ee unzip "$x" ;;
			*.Z )
				command -v uncompress >/dev/null || \
					{ echo "uncompress not found" >&2; continue; }
				ee uncompress "$x" ;;
			*.7z )
				command -v 7z >/dev/null || \
					{ echo "7z not found" >&2; continue; }
				ee 7z x "$x" ;;
			*)
				echo "Unsupported file type: $x" >&2 ;;
		esac
	done
}

# Set gedit embedded gnome-terminal path to home directory
if [[ $(ps -o comm= $PPID) == "gedit" ]]; then
	cd ~ || exit
fi

# PS1 Prompt
export PS1="\[\e[38;5;9m\][\[\e[38;5;11m\]\u\[\e[38;5;2m\]@\[\e[38;5;12m\]\h \
\[\e[38;5;5m\]\w\[\e[38;5;9m\]]\[\e[0m\]\$ "

# Elevated Power Actions
if [ "$(ps -p 1 -o comm=)" = "systemd" ] 2>/dev/null; then
	alias poweroff='systemctl poweroff'
	alias reboot='systemctl reboot'
else
	alias poweroff='loginctl poweroff'
	alias reboot='loginctl reboot'
fi

# Bottom Gruvbox Color Scheme
alias btm='btm --theme gruvbox'

# Skip Synth Shell if not in gnome-terminal, gedit, codium, or xfce4-terminal
term=$(ps -h -o comm -p $PPID)
if [[ $term != *gnome-terminal* ]] && \
	 [[ $term != "gedit" ]] && \
	 [[ $term != "codium" ]] && \
	 [[ $term != *xfce4-terminal* ]]; then
	return
fi

# Synth Shell Prompt
if [ "$distro" = "nixos" ]; then
	if [ -f "$HOME/.bashrc.d/synth-shell-prompt.sh" ] && \
		[ -n "$( echo $- | grep i )" ]; then
		source ~/.bashrc.d/synth-shell-prompt.sh
	fi
else
	if [ -f "$HOME/.config/synth-shell/synth-shell-prompt.sh" ] && \
		[ -n "$( echo $- | grep i )" ]; then
		source "$HOME/.config/synth-shell/synth-shell-prompt.sh"
	fi
fi