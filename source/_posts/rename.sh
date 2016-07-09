#!/usr/bin/env bash
for file in `ls *.png`
do
	mv "$file" `echo "$file" | sed 's/\(.*\)\(.png\)/test_\1\2/g'`
done