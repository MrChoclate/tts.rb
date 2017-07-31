require 'net/http'
require 'json'
require 'byebug'
require 'nokogiri'
require 'open-uri'
require 'optparse'


def call_api(language, page_number, base_path)
  language_key = ["en", "fr"].index(language) + 1

  url = "https://librivox.org/search/get_results?primary_key=#{language_key}&search_category=language&sub_category=&search_page=#{page_number}&search_order=alpha&project_type=solo"
  puts url
  uri = URI(url)

  request = Net::HTTP::Get.new(uri)
  request['X-Requested-With'] = 'XMLHttpRequest'
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  json = JSON.parse(response.body)
  process_results(json["results"], language, base_path) unless json["results"] == "No results"
end

def process_results(results, language, base_path)
  page =  Nokogiri::HTML(results)
  page.css('li').each do |li|
    book_link = li.css('a').map { |a| a['href'] }.select { |href| href.match(/^https?:\/\/librivox.org/) }.first&.strip
    zip_link = li.css('a').map { |a| a['href'] }.select { |href| href.match(/.zip$/) }.first
    if book_link && zip_link
      process_book(book_link, zip_link, language, base_path)
    else
      puts '<not found>'
      puts li.css('a').map { |a| a['href'] }
      puts '<not found/>'
    end
  end
end

def process_book(book_link, zip_link, language, base_path)
  book_link.gsub!(/http/, 'https') unless book_link.include? 'https'
  page = Nokogiri::HTML(open(book_link))

  book_title = page.css('div.page.book-page h1').first.text
  speaker_name = page.css('dt').select { |dt| dt.text.match(/Read by/)}.first.next_element.text
  escaped_book_title = escape(book_title)
  escaped_speaker_name = escape(speaker_name)


  online_text_href = page.css('a').select { |a| a['href'] && a.text && a['href'].match(/https?:\/\/www.gutenberg.org/) && a.text.match('Online text') }.map { |a| a['href'] }.first
  if online_text_href
    gutenberg_id = online_text_href.match(/\d+$/)
    text = get_gutenberg_text(gutenberg_id)
    unless text
      puts "text not found"
      puts book_link
      return
    end

    base_path = File.join(base_path, escaped_speaker_name)
    mkdir base_path

    base_path = File.join(base_path, escaped_book_title)
    mkdir base_path

    book_path = File.join(base_path, 'book.txt')
    zip_link_path = File.join(base_path, 'mp3.zip.link')
    File.write(book_path, text) unless File.exists?(book_path)

    # zip_path = "#{base_path}/mp3.zip"
    # mp3_path = "#{base_path}/mp3"
    # unless File.exists?(zip_path)
    #   `curl -L '#{zip_link}' > #{zip_path} && unzip #{zip_path} -d #{mp3_path}`
    # end
    File.write(zip_link_path, zip_link)
    puts [escaped_speaker_name, escaped_book_title, zip_link].join(' ')
  end
end

def get_gutenberg_text(id)
  uri = URI("http://www.gutenberg.org/files/#{id}/#{id}.txt")
  text = Net::HTTP.get(uri)
  if text.length < 1000
    uri = URI("http://www.gutenberg.org/cache/epub/#{id}/pg#{id}.txt")
    text = Net::HTTP.get(uri)
    return nil if text.length < 1000
  end
  text
end

def escape(s)
  s = s.downcase
  s = s.gsub(/ /, '_')
  s.gsub(/[^a-z_]/, '').chomp('_')
end

def mkdir(path)
  Dir.mkdir(path) unless File.exists?(path)
end

if __FILE__ == $0

  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: crawler.rb [options]"
    options[:data] = 'data'
    options[:language] = 'en'
    options[:start] = 1
    options[:end] = 1000

    opts.on("-d", "--data DATADIR", "data folder location, default to data/") do |d|
      options[:data] = d
    end

    opts.on("-l", "--language LANGUAGE", "language, default to en") do |d|
      options[:language] = d
    end

    opts.on("-s", "--start START", "page to start, default to 1") do |d|
      options[:start] = d.to_i
    end

    opts.on("-e", "--end END", "page to end crawling, default to 1000") do |d|
      options[:end] = d.to_i
    end
  end.parse!


  base_dir = options[:data]
  mkdir base_dir

  language = options[:language]
  mkdir File.join(base_dir, language)

  for i in options[:start]..options[:end]
    puts "Calling page #{i}"
    begin
      call_api(language, i, File.join(base_dir, language))
    rescue Exception => error
      puts error
      sleep 10
      retry
    end
  end
end


