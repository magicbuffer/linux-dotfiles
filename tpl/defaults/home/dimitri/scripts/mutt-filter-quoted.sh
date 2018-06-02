awk '/-----Original Message-----/ { level++; } 
    { for (i=0;i<level;++i) printf(">"); printf("%s%s", $0,"\n"); } '
