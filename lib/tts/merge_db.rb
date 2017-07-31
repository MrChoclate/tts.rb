require 'sequel'

def create_db(db)
  db.create_table? :speakers do
    primary_key :id
    String :name
    String :language
    String :sex
  end

  db.create_table? :words do
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
end

db_name_one = 'tts_phil_chenevert_copy.db'
db_name_two = 'elizabeth_klett.db'
db_name_result = 'merged.db'

def copy_db(db_one, to_merge, offset)
  db_one[:speakers].all.each do |speaker|
    speaker_id = speaker[:id]

    to_merge[:speakers].insert(
      id: speaker[:id] + offset,
      name: speaker[:name],
      language: speaker[:language]
    )

    words = db_one[:words].where(speaker_id: speaker_id).all
    words.each do |word|
      word[:speaker_id] += offset
      word[:id] += offset if word[:id]
      word[:next] += offset if word[:next]
      word[:previous] += offset if word[:previous]
    end
    to_merge.run("PRAGMA foreign_keys = 0")
    to_merge[:words].import([:id, :word, :start, :stop, :filename, :next, :previous, :speaker_id],
      words.map { |word| [word[:id], word[:word], word[:start], word[:stop], word[:filename], word[:next], word[:previous], word[:speaker_id]] }
    )
    to_merge.run("PRAGMA foreign_keys = 1")
  end
end

db_one = Sequel.connect("sqlite://#{db_name_one}")
db_two = Sequel.connect("sqlite://#{db_name_two}")
db_result = Sequel.connect("sqlite://#{db_name_result}")

create_db(db_one)
create_db(db_two)
create_db(db_result)

copy_db(db_one, db_result, 0)
copy_db(db_two, db_result, 10000000)