require "tts/version"
require "tts/tts"
require "tts/db"

module Tts
  class TtsError < StandardError
  end

  def self.speak(words, filename)
    words = words.map { |w| w.downcase }
    # Assert that all words are known
    words.each do |word|
      if !DB[:words][:word => word] then
        raise TtsError, "Word not found: #{word}"
      end
    end

    readers = get_db_words(words).map {|w| get_audio_buffer(w)}
    concat(filename, readers)
  end
end

Tts::speak(ARGV[0].split, "out.wav")