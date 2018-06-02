#/usr/bin/env zsh

local ret_status="%(?:%{$fg_bold[green]%}➜ %?:%{$fg_bold[red]%}➜ %?)%{$reset_color%}"
local username="%{$fg[white]%}%n%{$reset_color%}"
[[ $UID == 0 ]] && username="%{$fg_bold[red]%}%n%{$reset_color%}"

PROMPT='%{$fg[cyan]%}[${username}%{$fg[cyan]%}] [%{$fg[white]%}%~%{$fg[cyan]%}] $(git_prompt_info) >%{$reset_color%} '
RPROMPT='${ret_status}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[cyan]%}[%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg[cyan]%}]"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✘"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔"
