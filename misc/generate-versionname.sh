#!/bin/bash

SEED="$(echo "$@" | sha256sum )"
cat american-english.wordlist | \
	awk -v seed="$SEED" \
	'BEGIN{for(n=0;n<256;n++)ord[sprintf("%c",n)]=n;for (i=0;i<length(seed);i++){rinit+=ord[substr(seed,i+1,1)];}srand(rinit);}
         {w[++i]=$0}
	 END{n=2;for (j=0;j<n-1;j++){printf("%s-",w[int(i*rand())])};print(w[int(i*rand())])}'
