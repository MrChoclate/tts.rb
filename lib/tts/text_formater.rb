require "i18n"

I18n.available_locales = [:en]

def handle_accent(text, lang)
  if lang == "en"
    I18n.transliterate(text)
  else
    text
  end
end

def format_book(text, lang)
  handle_accent(text, lang)
    .downcase
    .strip
    .gsub(/’/, "'")
    .gsub(/[—\-_\n]/, ' ')
    .gsub(/[^a-zA-ZÀ-ÿ' ]/, '')
    .split(/\s/)
end

def format_sphinx_line(line, lang)
  split = line.split(/ +/)
  handle_accent(split.first, lang).gsub(/[^a-zA-ZÀ-ÿ \n]/, '')
end