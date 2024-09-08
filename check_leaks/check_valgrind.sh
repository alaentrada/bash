#!/bin/bash

a="$1.h"

if [ "$#" -eq 2 ]; then
	a=$2
fi

valgrind --leak-check=full --show-leak-kinds=all ./$1 2>val;


<$a grep ");" | awk '{print $2}' | tr '*' ' ' | tr '(' ' ' | awk '{print $1}' > funcs;



while read p; do 
	<val grep ": $p" && echo $p
done <funcs >myLeaks.log;
