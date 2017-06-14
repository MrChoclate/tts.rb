require 'securerandom'
require 'fileutils'

require "tts/version"
require "tts/tts"
require "tts/db"

module Tts
  class TtsError < StandardError
  end

  # load cmu dict
  @@dict = Hash.new "K L EH1 M AH0 N T"
  File.open("cmu.dict") do |file|
    file.each do |line|
      split = line.split
      word = split.first
      phonemes = split.slice(1, split.length).join(' ')
      @@dict[word] = phonemes
    end
  end

  def self.speak(words, filename)
    words = words.map { |w| w.downcase }

    readers = get_db_words(words).map do |w|
      if w.is_a? String
        get_buffer_from_unknown(w)
      else
        get_audio_buffer(w)
      end
    end
    concat(filename, readers)
  end

  def self.get_buffer_from_unknown(word)
    phonemes = get_phonemes(word)

    filename = "tmp.#{SecureRandom.uuid}.wav"
    `python3 ptowav.py '#{phonemes}' #{filename}`

    converted_filename = "tmp.#{SecureRandom.uuid}.16khz.wav"
    `ffmpeg -i #{filename} -ar 16000 #{converted_filename}`
    FileUtils.rm filename

    buffer = get_audio_buffer_from_file(converted_filename, 0, 100)
    FileUtils.rm converted_filename

    buffer
  end

  def self.get_phonemes(word)
    @@dict[word]
  end
end

if __FILE__ == $0
  Tts::speak(ARGV[0].split, ARGV[1])
end