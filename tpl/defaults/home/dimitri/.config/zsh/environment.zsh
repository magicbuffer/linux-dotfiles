# Keep the shell history in .cache
HISTFILE="$HOME/.cache/zsh/history"
[[ ! -d "$(dirname $HISTFILE)" ]] && mkdir -p "$(dirname $HISTFILE)"

# Size of the shell history
export SAVEHIST=20000
HISTSIZE=$(( $SAVEHIST * 1.10 ))

# Report stats if commands runs longer than
export REPORTTIME=30
# The format of process time reports with the time builtin.
export TIMEFMT="%J  %U user %S system %P cpu %*E total | Mem: %M kb max"

export BROWSER="chromium"
export PAGER=less
export GTK_THEME=Adwaita:dark
export PATH="$HOME/scripts:/opt/flair72/bin/linux:/opt/idafree-7.0:/usr/lib/ruby/gems/2.6.0:$PATH"
export EDITOR=vim

# less history file
export LESSHISTFILE=".cache/less/history"
[[ ! -d "$(dirname $LESSHISTFILE)" ]] && mkdir -p "$(dirname $LESSHISTFILE)"

export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=256

