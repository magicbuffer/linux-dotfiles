# -*- mode: sh;-*-
zmodload zsh/terminfo

local k

typeset -A key
key=(
  'Control'   '\C-'
  'Escape'    '\e'
  'Meta'      '\M-'
  'Backspace' "^?"
  'Delete'    "^[[3~"
  'F1'        "$terminfo[kf1]"
  'F2'        "$terminfo[kf2]"
  'F3'        "$terminfo[kf3]"
  'F4'        "$terminfo[kf4]"
  'F5'        "$terminfo[kf5]"
  'F6'        "$terminfo[kf6]"
  'F7'        "$terminfo[kf7]"
  'F8'        "$terminfo[kf8]"
  'F9'        "$terminfo[kf9]"
  'F10'       "$terminfo[kf10]"
  'F11'       "$terminfo[kf11]"
  'F12'       "$terminfo[kf12]"
  'Insert'    "$terminfo[kich1]"
  'Home'      "$terminfo[khome]"
  'PageUp'    "$terminfo[kpp]"
  'End'       "$terminfo[kend]"
  'PageDown'  "$terminfo[knp]"
  'Up'        "$terminfo[kcuu1]"
  'Left'      "$terminfo[kcub1]"
  'Down'      "$terminfo[kcud1]"
  'Right'     "$terminfo[kcuf1]"
  'BackTab'   "$terminfo[kcbt]"
)

for k in "${(k)key[@]}"
do
	if [[ -z "$key[$k]" ]]
	then
		key["$k"]='�'
	fi
done

# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} ))
then
  function zle-line-init()
  {
    echoti smkx
  }
  function zle-line-finish()
  {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

magic-pipe insert_grep  "grep \"@@@\"" "grep -i \"@@@\"" "grep -v \"@@@\"" "grep @@@"
magic-pipe insert_head "head"
magic-pipe insert_tail "tail"
magic-pipe insert_less "less"

zstyle ':completion:hist-complete:*' completer _history

autoload insert-unicode-char
zle -N insert-unicode-char

zle -N beginning-of-somewhere                beginning-or-end-of-somewhere
zle -N end-of-somewhere                      beginning-or-end-of-somewhere
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end  history-search-end
zle -C hist-complete                         complete-word _generic

# Movment keys
bind2maps emacs             --    Home                           beginning-of-somewhere
bind2maps       viins vicmd --    Home                           vi-beginning-of-line
bind2maps emacs             --    End                            end-of-somewhere
bind2maps       viins vicmd --    End                            vi-end-of-line
bind2maps emacs             --    Insert                         overwrite-mode
bind2maps       viins vicmd --    Insert                         vi-insert
bind2maps emacs             --    Delete                         delete-char
bind2maps       viins vicmd --    Delete                         vi-delete-char
bind2maps emacs viins vicmd --    Up                             history-substring-search-up
bind2maps emacs viins vicmd --    Down                           history-substring-search-down
bind2maps emacs             --    Left                           backward-char
bind2maps       viins vicmd --    Left                           vi-backward-char
bind2maps emacs             --    Right                          forward-char
bind2maps       viins vicmd --    Right                          vi-forward-char
bind2maps emacs             --    Backspace                      backward-delete-char
bind2maps       viins vicmd --    Backspace                      vi-backward-delete-char
bind2maps emacs viins       --    PageUp                         history-beginning-search-backward-end
bind2maps emacs viins       --    PageDown                       history-beginning-search-forward-end
## History navigation
bind2maps emacs             -- -s "$key[Control]P"               history-substring-search-up
bind2maps emacs             -- -s "$key[Control]N"               history-substring-search-down
bind2maps emacs viins vicmd -- -s '^X^G'                         per-directory-history-toggle-history
bind2maps emacs       vicmd -- -s "$key[Control]x$key[Control]x" history-beginning-search-menu
# Custom stuff
#bind2maps emacs             -- -s "$key[Control]$key[Left]"      backward-word
#bind2maps emacs             -- -s "$key[Control]$key[Right]"     forward-word
bind2maps emacs             -- -s "$key[Control]a"               emacs-backward-word
bind2maps emacs             -- -s "$key[Control]d"               emacs-forward-word
bind2maps emacs viins vicmd -- -s "$key[Control]b"               backward-kill-line
bind2maps emacs viins vicmd -- -s "$key[Control]f"               forward-kill-line
bind2maps emacs viins       -- -s "$key[Control]t"               insert-datestamp
bind2maps emacs viins       -- -s "$key[Control]s$key[Control]u" sudo-command-line
bind2maps emacs viins       -- -s "$key[Escape]$key[Backspace]"  slash-backward-kill-word
bind2maps emacs viins       -- -s "$key[Escape]$key[Delete]"     slash-forward-kill-word
bind2maps emacs viins       -- -s "$key[Control]g"               insert_grep
bind2maps emacs viins       -- -s "$key[Control]h"               insert_head
bind2maps emacs viins       -- -s "$key[Control]l"               insert_less
bind2maps emacs viins       -- -s "$key[Control]t"               insert_tail
bind2maps emacs viins vicmd -- -s \'                             magic-single-quotes
bind2maps emacs viins vicmd -- -s \"                             magic-double-quotes
bind2maps emacs viins vicmd -- -s \)                             magic-parentheses
bind2maps emacs viins vicmd -- -s \]                             magic-square-brackets
bind2maps emacs viins vicmd -- -s \}                             magic-curly-brackets
bind2maps emacs viins vicmd -- -s \>                             magic-angle-brackets
bind2maps emacs viins       -- -s "$key[Control]x"               zaw

bind2maps emacs viins vicmd -- -s "$key[Control]u"               insert-unicode-char
