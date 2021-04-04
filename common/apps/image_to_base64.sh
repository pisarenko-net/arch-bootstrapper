#!/bin/bash
for f in *jpeg;
do
    new_filename=`echo ${f} | base64`
    base64 ${f} > ~/Downloads/${new_filename}.safe
done;
