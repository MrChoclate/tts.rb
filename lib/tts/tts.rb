require_relative 'db'
require 'wavefile'
include WaveFile

module Tts
  def self.get_audio_buffer(word)
    get_audio_buffer_from_file(word[:filename], word[:start], word[:stop])
  end

  def self.get_audio_buffer_from_file(filename, start, stop)
    reader = Reader.new(filename)
    rate = reader.native_format.sample_rate

    reader.read((start * rate).to_i)
    buffer = reader.read(((stop - start) * rate).to_i)

    buffer
  end

  def self.concat(filename, buffers)
    Writer.new(filename, Format.new(:mono, :pcm_16, 16000)) do |writer|
      buffers.each do |buffer|
        writer.write(buffer)
      end
    end
  end

  def self.get_db_words(words, speaker_id)
    kept_words = []
    len = 1

    while words && words.length > 0 do
      db_words = DB[:words].where(speaker_id: speaker_id, word: words.first)

      if db_words.count == 0
        kept_words << words.first
        words = words.slice(1, words.length)
        next
      end

      potential_next = DB[:words].where(speaker_id: speaker_id, id: db_words.map {|w| w[:next]}, word: words[len]).all
      while potential_next.length > 0 do
        len += 1
        db_words = potential_next
        potential_next = DB[:words].where(speaker_id: speaker_id, id: db_words.map {|w| w[:next]}, word: words[len]).all
      end
      to_kept = []
      kept = db_words.first
      len.times do
        to_kept << kept
        kept = DB[:words][:id => kept[:previous]]
      end
      puts to_kept.last[:filename]
      concat_word = {
        :word => to_kept.map {|w| w[:word]}.reverse.join(" "),
        :filename => to_kept.first[:filename],
        :start => to_kept.last[:start],
        :stop => to_kept.first[:stop]
      }
      kept_words.push(concat_word)
      words = words.slice(len, words.length)
      len = 1
    end
    puts kept_words
    kept_words
  end
end
