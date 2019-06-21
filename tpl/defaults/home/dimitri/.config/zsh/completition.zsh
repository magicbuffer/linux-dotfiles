# Automatically update PATH entries
zstyle ':completion:*' rehash true

# If not then paste is way to slow
zstyle ':bracketed-paste-magic' active-widgets '.self-*'

# Don't try parent path completion if the directories exist
zstyle ':completion:*' accept-exact-dirs true

# Prettier completion for processes
zstyle ':completion:*:*:*:*:processes' force-list always
zstyle ':completion:*:*:*:*:processes' menu yes select
zstyle ':completion:*:*:*:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,args -w -w"
