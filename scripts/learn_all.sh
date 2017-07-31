#!/bin/zsh

time find data_crawl/en/elizabeth_klett -iname '*.wav'|DB_NAME=elizabeth_klett2.db xargs -P 1 -n 1 bundle exec ruby lib/tts/learn.rb
