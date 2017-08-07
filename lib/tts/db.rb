require 'sequel'
require 'byebug'

module Tts
  db_name = ENV['DB_NAME'] || 'tts_phil_chenevert.db'
  DB = Sequel.connect("sqlite://#{db_name}")
  puts "Using db: #{db_name}"

  DB.create_table? :speakers do
    primary_key :id
    String :name
    String :language
    String :sex
  end

  DB.create_table? :words do
    primary_key :id
    String :word
    Float :start
    Float :stop
    String :filename
    TrueClass :can_recover
    foreign_key :next, :words
    foreign_key :previous, :words, deferrable: true
    foreign_key :speaker_id, :speakers, deferrable: true
  end

  def self.find_begin(found_words, real_words)
    i = 0
    first_words = found_words.slice(0, CORRECT_IN_A_ROW).map {|w| w.word}
    while first_words != real_words.slice(i, CORRECT_IN_A_ROW) do
      i += 1
    end

    i
  end

  def self.process(found_words, real_words, start, file_path, speaker_id)
    real_words = real_words.slice(start, real_words.length)
    i = 0
    id = if DB[:words].all.length == 0 then 1 else DB[:words].max(:id) + 1 end

    old_word_id = nil
    to_add = []
    found_words.each do |word|
      is_next = true
      while word.word != real_words[i] do
        i += 1
        is_next = false
        if i > real_words.length then
          puts word.word
        end
      end

      word_id = id
      to_add.push([id, word.word, word.start, word.stop, file_path, nil, nil, speaker_id])
      id += 1

      if is_next && old_word_id then
        to_add[-2][5] = word_id
        to_add[-1][6] = old_word_id
      end

      old_word_id = word_id
      i += 1
    end
    DB.run("PRAGMA foreign_keys = 0")
    DB[:words].import([:id, :word, :start, :stop, :filename, :next, :previous, :speaker_id], to_add)
    DB.run("PRAGMA foreign_keys = 1")
  end

  def self.save_db(found_words, real_words, wav_path, speaker_name, language)
    speaker = DB[:speakers].where(name: speaker_name).first
    if speaker
      speaker_id = speaker[:id]
    else
      speaker_id = DB[:speakers].insert(name: speaker_name, language: language)
    end

    process(found_words, real_words, find_begin(found_words, real_words), wav_path, speaker_id)
  end
end

