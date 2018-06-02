#!/usr/env zsh
#
# magic-pipe <name> <template...>
# Original source from: http://www.zsh.org/mla/users/2008/msg00708.html
# 
declare -gA pipe_widgets

function magic-pipe()
{
	local var=$1 
	local templates=_${var}_templates
	declare -ga $templates
	shift
	set -A $templates $@ "--"
	zle -N $var insert-pipe
}

function insert-pipe()
{
    emulate -L zsh

    local var=$WIDGET
    local templates=_${var}_templates
    local before after auto_accept same patnum

    set nomatch
    # see if command line is same as in our last invocation
    if [[ $CURSOR == ${pipe_widgets[cursor_$var]} && 
		  $HISTNO == $pipe_widgets[histno_$var] && 
		  $BUFFER == $pipe_widgets[buffer_$var] ]]
	then
        (( patnum = ++pipe_widgets[patnum_$var] ))
        # wrap around
        if [[ $patnum -gt ${#${(P)templates}}  ]]
		then
            (( patnum = pipe_widgets[patnum_$var] = 1 ))
        fi
        BUFFER=$pipe_widgets[buffer_before_$var]
        CURSOR=$pipe_widgets[cursor_before_$var]
    else
       # start from scratch
       (( patnum = pipe_widgets[patnum_$var] = 1 ))
       pipe_widgets[buffer_before_$var]=$BUFFER
       pipe_widgets[cursor_before_$var]=$CURSOR
    fi
    
	# Get the current template
	local tmp=${${(P)templates}[$patnum]}
    
	# Shall we accept the command
	if [[ $tmp == *\\n ]]
	then
        auto_accept=1
        tmp=$tmp[1,-3]
    fi
    
	# If not specified position the cursor at the end
    if [[ $tmp != *@@@* ]]
	then
        tmp="${tmp}@@@"
    fi

	# Shall we append a template?
	if [[ $tmp != --@@@ ]]
	then
    	before=${tmp%@@@*}
    	after=${tmp#*@@@}
    	
		if [[ -n ${LBUFFER## *} ]]
		then
    	    RBUFFER+=" | "
	    else
    	    if [[ $after == '' && $before[-1] != " " ]]
			then
            	before+=" "
	        fi
    	    auto_accept=
	    fi	
	fi

	# Generate the resulting buffer and compute the cursor position
    RBUFFER+=$before$after
    CURSOR=$(( $#BUFFER - $#after))

    # VI mode support
    builtin zle vi-insert 
    if [[ $auto_accept == 1 ]]
	then
        builtin zle accept-line
    fi

    pipe_widgets[histno_$var]=$HISTNO
    pipe_widgets[buffer_$var]=$BUFFER
    pipe_widgets[cursor_$var]=$CURSOR
}
