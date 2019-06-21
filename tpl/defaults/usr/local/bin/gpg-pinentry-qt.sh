#!/bin/sh
#
# Wrapper around gpg to use pinentry-qt via pinentry-selector.sh
#

export PINENTRY_USER_DATA=qt
gpg $@
