#!/bin/zsh

for line in $(find data/ -iname '*.mp3'); do
    base="data$(echo $line |cut -d '/' -f 2-4)"
    echo $base
    name=$(echo $line |cut -d '/' -f 6-|cut -d "." -f 1);
    mkdir "$base/wav"
    ffmpeg -i "$base/mp3/$name.mp3" -ar 16000 -ac 1 "$base/wav/$name.wav";
done
