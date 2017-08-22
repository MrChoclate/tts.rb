require 'pocketsphinx-ruby'
require 'wavefile'
require 'fileutils'
require 'securerandom'
include WaveFile
require_relative 'levenshtein/levenshtein'


Word = Struct.new(:word, :start, :stop)
CORRECT_IN_A_ROW = 5
# Create only one decoder to avoid allocating a lot of memory
DECODER = Pocketsphinx::Decoder.new(Pocketsphinx::Configuration.default)


def model_path
  model_path = `pkg-config --variable=modeldir pocketsphinx`.strip
end

def french_dict
  "#{model_path}/fr_FR/frenchWords62K.dic"
end

def english_dict
  "tts.dict"
end

def french_hmm
  "#{model_path}/fr_FR/french_f0/"
end

def french_lm
  "#{model_path}/fr_FR/french3g62K.lm.bin"
end

def sphinx(wav_path, language)
  if language == 'en' then
    `pocketsphinx_continuous -dict #{english_dict} -infile "#{wav_path}" -time yes`
  else
    `pocketsphinx_continuous -dict #{french_dict} -hmm #{french_hmm} -lm #{french_lm} -infile "#{wav_path}" -time yes`
  end
end

def read_output(output, language)
  words = []
  sentence_end_time = nil
  sentence = old_sentence = ""
  output.each_line do |line|
    if /[0-9]\./.match(line) && !/[<\[]/.match(line) then
      split = line.split(/ +/)
      word = format_sphinx_line(line, language)
      start, stop = split.slice(1, 2).map { |x| x.to_f }
      word = Word.new(word, start, stop)
      words.push(word)
    elsif /<s>/.match(line) then
      sentence_begin_time = line.split(' ')[1].to_f
      if sentence_end_time != nil && (sentence_end_time > sentence_begin_time) then
        # Something went wrong with the timing (we went back in time !), remove previous sentence
        # See https://github.com/cmusphinx/pocketsphinx/issues/73
        words.pop(old_sentence.split(' ').length)
      end
    elsif /<\/s>/.match(line) then
      sentence_end_time = line.split(' ')[1].to_f
    elsif !/[0-9]/.match(line) then
      old_sentence = sentence
      sentence = line
    end
  end
  puts words
  words
end

def get_begining(ops)
  real_words_indice = found_words_indice = correct_count = 0

  ops.each_with_index do |op, indice|
    if op == SAME
      correct_count += 1
      if correct_count == CORRECT_IN_A_ROW then
        puts CORRECT_IN_A_ROW, real_words_indice - CORRECT_IN_A_ROW + 1, found_words_indice - CORRECT_IN_A_ROW + 1, indice - CORRECT_IN_A_ROW + 1
        return real_words_indice - CORRECT_IN_A_ROW + 1, found_words_indice - CORRECT_IN_A_ROW + 1, indice - CORRECT_IN_A_ROW + 1
      end
    else
      correct_count = 0
    end

    if op != ADD then
      real_words_indice += 1
    end
    if op != DEL then
      found_words_indice += 1
    end
  end
end

def extract_audio(input_filename, output_filename, start, stop)
  Writer.new(output_filename, Format.new(:mono, :pcm_16, 16000)) do |writer|
    reader = Reader.new(input_filename)
    rate = reader.native_format.sample_rate

    reader.read(start * rate)
    buffer = reader.read((stop - start) * rate)

    writer.write(buffer)
  end
end

def recover(audio_file, real_sentence, language)
  configuration = Pocketsphinx::Configuration::Grammar.new do
    sentence real_sentence
  end
  if language == 'fr' then
    configuration['dict'] = french_dict
    configuration['lm'] = french_lm
    configuration['hmm'] = french_hmm
  else
    configuration['dict'] = english_dict
  end

  begin
  DECODER.reconfigure(configuration)
  rescue Pocketsphinx::API::Error
    return
  end

  DECODER.decode audio_file

  words = DECODER.words
  if words.length > 0 then
    return words
  end
end

def process_since_begining(real_words, found_words, words, input_filename, ops, language)
  real_start, found_start, ops_start = get_begining(ops)
  ops = ops.slice(ops_start, ops.length)

  real_last_correct = real_indice = real_start
  found_last_correct = found_indice = found_start
  recording_correct = true

  new_words = []
  ops.each_with_index do |op, indice|
    if op == SAME then
      if words[found_indice].word != real_words[real_indice] then
        puts words[found_indice].word, real_words[real_indice], found_indice, real_indice
        fail
      end
      if recording_correct then
        puts words[found_indice]
        new_words << words[found_indice]
      else
        recording_correct = true
        correct_words = real_words.slice(real_last_correct + 1, real_indice - real_last_correct)
        false_words = words.slice(found_last_correct + 1, found_indice - found_last_correct)

        #puts "correcting"
        #puts false_words
        #puts "with"
        #puts words[found_indice]

        filename = "tmp.#{SecureRandom.uuid}.wav"
        extract_audio(input_filename, filename, false_words.first.start, false_words.last.stop)
        w = recover(filename, correct_words.join(' '), language)
        FileUtils.rm filename

        if w && w.first.start_frame == 0 then
          w.select! {|w| /^[a-z]/.match(w.word)}  # ignore silence
          w = w.map { |e| Word.new(e.word.gsub(/[^a-z]/, ''), false_words.first.start + e.start_frame * 0.01, false_words.first.start + e.end_frame * 0.01)}
          for i in 0..w.length - 1
            puts w[i]
            new_words << w[i]
          end
        else # recover fail
          puts words[found_indice]
          new_words << words[found_indice]
        end
      end

      found_last_correct = found_indice
      real_last_correct = real_indice
    else
      recording_correct = false
    end

    if op != ADD then
      real_indice += 1
    end
    if op != DEL then
      found_indice += 1
    end
  end

  new_words
end