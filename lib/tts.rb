require 'securerandom'
require 'fileutils'

require "tts/version"
require "tts/tts"
require "tts/db"
require "tts/text_formater"

module Tts
  class TtsError < StandardError
  end

  # load cmu dict
  @@en_dict = Hash.new
  File.open("cmu.dict") do |file|
    file.each do |line|
      split = line.split
      word = split.first
      phonemes = split.slice(1, split.length).join(' ')
      @@en_dict[word] = phonemes
    end
  end

  @@fr_dict = Hash.new
  File.open("fr.dict") do |file|
    file.each do |line|
      split = line.split
      word = split.first
      phonemes = split.slice(1, split.length).join(' ')
      @@en_dict[word] = phonemes
    end
  end

  def self.speak(words, filename, speaker_id)
    speaker = DB[:speakers].where(id: speaker_id).first
    language = speaker[:language]
    words = format_book(words, language)

    readers = get_db_words(words, speaker_id).map do |w|
      if w.is_a? String
        get_buffer_from_unknown(w, language)
      else
        get_audio_buffer(w)
      end
    end
    concat(filename, readers)
  end

  def self.get_buffer_from_unknown(word, language)
    phonemes = get_phonemes(word, language)

    filename = "tmp.#{SecureRandom.uuid}.wav"
    `python3 ptowav.py '#{phonemes}' #{filename} #{language}`

    converted_filename = "tmp.#{SecureRandom.uuid}.16khz.wav"
    `ffmpeg -i #{filename} -ar 16000 #{converted_filename}`
    FileUtils.rm filename

    buffer = get_audio_buffer_from_file(converted_filename, 0, 100)
    FileUtils.rm converted_filename

    buffer
  end

  def self.get_phonemes(word, language)
    if language == "en" then
      @@en_dict[word] || self.build_phonemes(word, language)
    else
      @@fr_dict[word] || self.build_phonemes(word, language)
    end
  end

  def self.build_phonemes(word, language)
    `(cd g2p && env/bin/python train.py '#{word}' '#{language}')`
  end
end

if __FILE__ == $0
  Tts::speak(ARGV[0], ARGV[1], ARGV[2].to_i)
end