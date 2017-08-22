require 'set'
require_relative 'text_formater'

dict = Set.new
File.read('fr.dict').each_line do |line|
  dict.add(line.split()[0])
end

def get_book_words(book_path)
  book_words = format_book(File.read(book_path), 'fr').to_set
end

todo = Set.new

books = `find data_fr/fr/nadine_eckertboulet -name "*.txt"`.split("\n")
#books = ['data_crawl/en//zachary_brewstergeisz/the_man_who_was_thursday_a_nightmare/book.txt']

books.each do |book|
  puts book
  todo.merge(get_book_words(book) - dict)
  puts todo.size
end

File.open("todo", "w") do |file|
  todo.sort.each do |word|
    file.write("#{word}\n") if word.length < 30
  end
end