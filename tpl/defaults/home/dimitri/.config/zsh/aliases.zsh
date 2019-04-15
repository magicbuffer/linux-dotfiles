#!/bin/env zsh

local openvpn_wrapper="/usr/local/bin/openvpn-wrapper.sh"
# tcp vpn aliases
alias vpn-australia-tcp="$openvpn_wrapper start cyberghost australia tcp"
alias vpn-france-tcp="$openvpn_wrapper start cyberghost france tcp"
alias vpn-hong-kong-tcp="$openvpn_wrapper start cyberghost hong-kong tcp"
alias vpn-italy-tcp="$openvpn_wrapper start cyberghost italy tcp"
alias vpn-japan-tcp="$openvpn_wrapper start cyberghost japan tcp"
alias vpn-singapore-tcp="$openvpn_wrapper start cyberghost singapore tcp"
alias vpn-sweden-tcp="$openvpn_wrapper start cyberghost sweden tcp"
alias vpn-switzerland-tcp="$openvpn_wrapper start cyberghost switzerland tcp"
alias vpn-ukraine-tcp="$openvpn_wrapper start cyberghost ukraine tcp"
alias vpn-united-kingdom-tcp="$openvpn_wrapper start cyberghost united-kingdom tcp"
alias vpn-united-states-tcp="$openvpn_wrapper start cyberghost united-states tcp"
alias vpn-argentina-tcp="$openvpn_wrapper start cyberghost argentina tcp"
alias vpn-brazil-tcp="$openvpn_wrapper start cyberghost brazil tcp"
# udp vpn aliases
alias vpn-australia-udp="$openvpn_wrapper start cyberghost australia udp"
alias vpn-france-udp="$openvpn_wrapper start cyberghost france udp"
alias vpn-hong-kong-udp="$openvpn_wrapper start cyberghost hong-kong udp"
alias vpn-italy-udp="$openvpn_wrapper start cyberghost italy udp"
alias vpn-japan-udp="$openvpn_wrapper start cyberghost japan udp"
alias vpn-singapore-udp="$openvpn_wrapper start cyberghost singapore udp"
alias vpn-sweden-udp="$openvpn_wrapper start cyberghost sweden udp"
alias vpn-switzerland-udp="$openvpn_wrapper start cyberghost switzerland udp"
alias vpn-ukraine-udp="$openvpn_wrapper start cyberghost ukraine udp"
alias vpn-united-kingdom-udp="$openvpn_wrapper start cyberghost united-kingdom udp"
alias vpn-united-states-udp="$openvpn_wrapper start cyberghost united-states udp"
alias vpn-argentina-udp="$openvpn_wrapper start cyberghost argentina udp"
alias vpn-brazil-udp="$openvpn_wrapper start cyberghost brazil udp"
# default to tcp
alias vpn-australia="vpn-australia-tcp"
alias vpn-france="vpn-france-tcp"
alias vpn-hong-kong="vpn-hong-kong-tcp"
alias vpn-italy="vpn-italy-tcp"
alias vpn-japan="vpn-japan-tcp"
alias vpn-singapore="vpn-singapore-tcp"
alias vpn-sweden="vpn-sweden-tcp"
alias vpn-switzerland="vpn-switzerland-tcp"
alias vpn-ukraine="vpn-ukraine-tcp"
alias vpn-united-kingdom="vpn-united-kingdom-tcp"
alias vpn-united-states="vpn-united-states-tcp"
alias vpn-argentina="vpn-argentina-tcp"
alias vpn-brazil="vpn-brazil-tcp"

# Default applications
alias email="mutt"
alias music="cmus"
alias top="htop"
alias vi=vim
alias ssh='TERM=xterm ssh'
alias startx='ssh-agent startx'
alias diff='diff --color'

# Systemd
alias start="sudo systemctl start"
alias stop="sudo systemctl stop"
alias restart="sudo systemctl restart"
alias status="systemctl status"

# Zsh
alias zsh-clean-history="shred -u $HISTFILE"
alias zsh-zle-list-widgets="zle -al"

# Git
alias gl="git log --graph --show-signature"
alias gba="git branch -av"
alias gr="git remote -v"

# Trailing
alias -g S=' | sort '
alias -g U=' | uniq -c '
alias -g N=' | sort -nr '
