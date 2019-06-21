#!/bin/sh
#
# Select a pinentry program based on the value
# of the PINENTRY_USER_DATA environment variable.
#
# The default pinentry is cursed...
#
case $PINENTRY_USER_DATA in
gtk)
    exec /usr/bin/pinentry-gtk-2 "$@"
    ;;
qt)
    exec /usr/bin/pinentry-qt "$@"
    ;;                                                                                               
*)
    exec /usr/bin/pinentry-curses
    ;;
esac

