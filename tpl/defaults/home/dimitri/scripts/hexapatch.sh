#!/bin/bash
# Copyright (c) 2017 d@magicbuffer.net
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

function error()
{
	echo "ERROR: $@">&2
	exit -1
}

function warning()
{
	echo "WARNING: $@">&2
}

function debug()
{
	if [[ -z $debug ]]
	then
		return
	fi

	echo "DEBUG: $@">&2
}

function to-hex()
{
	local value=$1
	local value_format=${value:0:2}
	local value_data=${value:2}
	local value_hex

	debug "function to-hex()"
	debug "value        : $value"
	debug "value_format : $value_format"
	debug "value_data   : $value_data"
	
	case "$value_format" in
	0b)
		value_hex=$(echo "obase=16; ibase=2; $value_data" | bc)
		;;
	0o)
		value_hex=$(echo "obase=16; ibase=8; $value_data" | bc)
		;;
	0d)
		value_hex=$(echo "obase=16; ibase=10; $value_data" | bc)
		;;
	0x)
		value_hex="$value_data"
		;;
	0s)
		value_hex=$(echo -n "$value_data" | xxd -p)
		;;
	esac

	echo -n "$value_hex"
}

function patch-at-offset()
{
	local file=$1
	local offset=$2
	local patch=$3
	
	debug "patch-at-offset()"
	debug "file   : $file"
	debug "offset : $offset"
	debug "patch  : $patch"

	echo -n "$patch" | xxd -p -r | dd of="$file" bs=1 count=$(($(echo -n "$patch" | wc -c)/2)) seek=$offset conv=notrunc 2>/dev/null
}

function search-pattern()
{
	local file=$1
	local pattern=$2

	debug "search-pattern()"
	debug "file    : $file"
	debug "pattern : $pattern"

	echo $(xxd -p "$file" | tr -d '\n' | grep -ibo "$pattern")
}

function usage()
{
	echo "Usage: $(basename $0) -f <file> -s <pattern> [-p <patch>] [-n <n>]" >&2
	echo "Search in <file> for <n> occurences of <pattern> replacing them by <patch> if supplied."
	echo "  -f  : The file to operate on."
	echo "  -s  : Specify the pattern to search."
	echo "  -p  : Specfiy the patch to apply."
	echo "  -n  : The expected number of occurences (Default: 1 if <patch> is given otherwise -1)"
	echo "Note: <pattern> and <patch> must be prefixed by one of the following format specifier:"
	echo "  0b : binary"
	echo "  0o : octal"
	echo "  0d : decimal"
	echo "  0x : hexadecimal"
    echo "  0s : ascii string"
	exit 1
}

while getopts ":f:s:p:n:" o
do
	case "${o}" in
	f)
		file=$OPTARG ;;
	s)
		search=$OPTARG ;;
	p)
		patch=$OPTARG ;;
	n)
		n=$OPTARG ;;
        *)
		usage;;
	esac
done
#shift $((OPTIND-1))

if [[ -z $file ]]
then
	usage
fi
if [[ -z $search ]]
then
	usage
fi
if [[ -z $n && ! -z $patch ]]
then
	n=1
fi
if [[ -z $n ]]
then
	n=-1
fi

if [[ ! -f $file ]]
then
	error "The specified file cannot be read '$file'"
fi

search_hex=$(to-hex "$search")
if [[ -z $search_hex ]]
then
	error "Failed to convert the search pattern '$search' to hexadecimal"
fi

if [[ ! -z $patch ]]
then
	# Patch the file
	patch_hex=$(to-hex "$patch")
	if [[ -z $patch_hex ]]
	then
		error "Failed to convert the replacement pattern '$patch' to hexadecimal"
	fi
fi

matches=$(search-pattern "$file" $search_hex)
matches_count=$(echo "$matches" | wc -w)

if [[ $matches_count -le 0 ]]
then
	error "No matches found"
fi
if [[ $n -ne -1 ]]
then
	if [[ $matches_count -gt $n ]]
	then
		error "More than $n match"
	fi
	if [[ $matches_count -lt $n ]]
	then
		error "Less than $n match"
	fi
fi

for match in $matches
do
	echo "$match"
	
	pos=$(echo $match | cut -d ":" -f 1)
	# pos must be even to enforce byte boundary
	if [ $((pos%2)) -ne 0 ]
	then
		#warning "Not on byte boundary"
		continue
	fi

	offset=$((pos/2))
	#value=$(dd if="$file" bs=1 count=1 skip=$offset 2>/dev/null | xxd -p | tr -d '\n')
	if [[ ! -z $patch_hex ]]
	then
		patch-at-offset "$file" "$offset" "$patch_hex"
	fi
done

