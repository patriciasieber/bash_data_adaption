#!/bin/bash
i=1
fileName="separate_filtered_as_$i"
while read line ; do 
if [ "$line"  == ""  ] ; then
 ((++i))
 fileName="separate_filtered_as_$i"
else
 echo $line >> "$fileName"
fi
done
