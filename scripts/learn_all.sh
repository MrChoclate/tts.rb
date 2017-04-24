#!/bin/zsh

time find data -iname '*.wav'|xargs -P 4 -n 1 bundle exec ruby lib/tts/learn.rb