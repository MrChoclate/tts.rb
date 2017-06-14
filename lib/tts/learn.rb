require 'pocketsphinx-ruby'
require 'byebug'
require_relative 'levenshtein/levenshtein'
require_relative 'process_sphinx'
require_relative 'db'


module Tts
  audio_file = ARGV[1]
  text_file = audio_file.split('/')[0..4].join("/") + "/book.txt"
  speaker_name = audio_file.split('/')[2]  # data/lang/speaker/bookname/wav/chapter1.wav

  parsed_words = read_output(sphinx(audio_file))
  real_words = File.read(text_file).downcase.strip.gsub(/’/, "'").gsub(/[—\-_]/, ' ').gsub(/[^a-zA-Z \n]/, '').split(/\W+/)

  found_words = parsed_words.map { |word| word.word }
  ops = get_levenshtein_ops(real_words, found_words)

  to_save_words = process_since_begining(real_words, found_words, parsed_words, audio_file, ops)
  save_db(to_save_words, real_words, audio_file, speaker_name)
end
