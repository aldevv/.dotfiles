#!/bin/bash

if [ -z "$2" ]; then
    curl cht.sh/"$1"
else
    curl cht.sh/"$1"/"$2"
fi
