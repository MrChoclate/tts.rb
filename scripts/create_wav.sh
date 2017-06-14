#!/bin/zsh

for line in $(find data_crawl/ -iname '*.mp3'); do
    base="data_crawl$(echo $line |cut -d '/' -f 2-5)"
    echo $base
    name=$(echo $line |cut -d '/' -f 7-|cut -d "." -f 1);
    mkdir "$base/wav"
    ffmpeg -i "$base/mp3/$name.mp3" -ar 16000 -ac 1 "$base/wav/$name.wav";
done
