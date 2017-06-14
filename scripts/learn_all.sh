#!/bin/zsh

time find data_crawl/en/phil_chenevert/ -iname '*.wav'|xargs -P 4 -n 1 bundle exec ruby lib/tts/learn.rb phil_chenevert.db
