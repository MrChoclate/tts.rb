require 'securerandom'
require 'byebug'

require_relative 'db'
require_relative 'process_sphinx'
require_relative 'tts'


module Tts
  DB[:words].all.each do |word|
    filename = "#{word[:word]}_#{SecureRandom.uuid}.wav"
    concat(filename, [get_audio_buffer(word)])
    word[:can_recover] = !!recover(filename, word[:word])
    DB[:words].where(id: word[:id]).update(word)
    File.delete(filename)
  end
end