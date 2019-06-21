#!/bin/sh
#
# Wrapper around gpg to use pinentry-curses via pinentry-selector.sh
#

export PINENTRY_USER_DATA=curses
gpg $@
