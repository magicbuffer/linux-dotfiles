#!/bin/sh
#
# Wrapper around gpg to use pinentry-gtk2 via pinentry-selector.sh
#

export PINENTRY_USER_DATA=gtk
gpg $@
