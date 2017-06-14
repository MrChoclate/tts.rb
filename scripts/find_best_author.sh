#!/bin/zsh

for line in $(find data_crawl_meta/en/* -type d -depth 0); do
  echo $(find "$line/"* -type d -depth 0 |wc -l) $line
done