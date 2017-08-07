#!/bin/zsh

time find data_fr/fr/nadine_eckertboulet -iname '*.wav'|DB_NAME=nadine_eckertboulet.db xargs -P 1 -n 1 bundle exec ruby lib/tts/learn.rb
