#!/usr/env zsh

local f
local here="$HOME/.config/zsh"

local _functions="$here/functions"
local _autoload_functions="$here/autoload/functions"
local _autoload_widgets="$here/autoload/widgets"

local _aliases="$here/aliases.zsh"
local _environment="$here/environment.zsh"
local _key_bindings="$here/key-bindings.zsh"
local _options="$here/options.zsh"
local _theme="$here/theme.zsh"
local _completition="$here/completition.zsh"

local _antigen_local="/usr/share/zsh/share/antigen.zsh"

# Register autoloaded functions and zle widgets
fpath=( "$_autoload_functions" "$_autoload_widgets" ${fpath[@]} )
for f in "$_autoload_functions/"*(N:t)
do
	autoload -Uz "$_autoload_functions/$f"
done
for f in "$_autoload_widgets/"*(N:t)
do
	autoload -Uz "$_autoload_widgets/$f"
	zle -N "$f"
done

# Register functions
for f in "$_functions/"*(N:t)
do
	source "$_functions/$f"
done

# Antigen
if [[ -f $_antigen_local ]]
then
	source "$_antigen_local"
else
	local _antigen_git="$(mktemp)"
	curl -L "https://git.io/antigen" > "$_antigen_git"
	source "$_antigen_git"
	rm "$_antigen_git"
fi
if is-callable antigen; then 
	antigen init "$here/antigenrc"
fi

# Aliases
[[ -f "$_aliases" ]] && source "$_aliases"
# Environ
[[ -f "$_environment" ]] && source "$_environment"
# Key Bindings
[[ -f "$_key_bindings" ]] && source "$_key_bindings"
# Options
[[ -f "$_options" ]] && source "$_options"
# Completition
[[ -f "$_completition" ]] && source "$_completition"
# Theme
[[ -f "$_theme" && -n "$fg" ]] && source "$_theme"

# Finally, shall we start X?
[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx
