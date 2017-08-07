require 'pocketsphinx-ruby'
require 'byebug'
require_relative 'levenshtein/levenshtein'
require_relative 'process_sphinx'
require_relative 'db'
require_relative 'text_formater'

module Tts
  audio_file = ARGV[0]
  text_file = audio_file.split('/')[0..3].join("/") + "/book.txt"
  speaker_name = audio_file.split('/')[2]  # data/lang/speaker/bookname/wav/chapter1.wav
  language = audio_file.split('/')[1]
  puts text_file, speaker_name, language

  parsed_words = read_output(sphinx(audio_file, language))
  real_words = format_book(File.read(text_file))

  found_words = parsed_words.map { |word| word.word }
  ops = get_levenshtein_ops(real_words, found_words)

  to_save_words = process_since_begining(real_words, found_words, parsed_words, audio_file, ops, language)
  save_db(to_save_words, real_words, audio_file, speaker_name, language)
end
