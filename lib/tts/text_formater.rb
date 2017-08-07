require "i18n"

I18n.available_locales = [:en]

def handle_accent(text)
  I18n.transliterate(text)
end

def format_book(text)
  handle_accent(text)
    .downcase
    .strip
    .gsub(/’/, "'")
    .gsub(/[—\-_]/, ' ')
    .gsub(/[^a-zA-Z \n]/, '')
    .split(/\W+/)
end

def format_sphinx_line(line)
  split = line.split(/ +/)
  handle_accent(split.first).gsub(/[^a-zA-Z \n]/, '')
end