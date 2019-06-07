require 'httparty'
require 'nokogiri'

BASE_URL = "https://www.gov.sg"

def fetch(url)
  begin
    response = HTTParty.get(url)
    return response.body
  rescue Exception => ex
    raise ex
  end
end

def parse_page(name, html)
  def link_must_contain(link, name)
    (link.include? "/sgdi/#{name}/") or (link.include? "ministries/")
  end
  doc = Nokogiri::HTML(html)
  # puts doc.class
  links = doc.css("a")
  # this can be simplified with reduce but i'm not going to bother
  links.select { |link| link.key? "href" and link_must_contain(link['href'], name) }
    .map{ | link | link["href"]}
end


def persist_html(name, contents)
  IO.write("./test/" + name + ".html", contents)
  # IO.write("./data/" + name + ".html", contents)
end

def dl_pages
  urls = [
    'https://www.gov.sg/sgdi/ministries',
    'https://www.gov.sg/sgdi/statutory-boards',
    'https://www.gov.sg/sgdi/organs-of-state',
  ]
  for url in urls do
    filename = url.split('/').last
    page = fetch(url)
    persist_html(filename, page)
  end
end

def crawl_page_for_email(url)
  contents = fetch(url)
  crawl_for_email(contents)
end

def crawl_for_email(contents)
  email_regex = /@[A-Za-z]+.(gov|edu).sg/
  doc = Nokogiri::HTML(contents)
  agency_title = doc.css(".agency-title")
    .css("h1")
    .first
    .text
  addr = doc.css("address")

  # find me the email
  email = addr.css("a")
    .map { |a| (a.key? "text" ? a.text : nil) }
    .select { |text| text != false and text.match(email_regex) }

  if email.length == 0
    div = doc.css('.section-body')
      .map {|d| d.css('.email')}
      .flatten
      .drop_while { |d| d.text.strip.length == 0 }

    if div.length > 0
      matches =  div.first.text.match(email_regex)
      if matches != nil
        email = matches.string
      end
    end
  end

  # for those pages where email is not found in .section-body
  # eg AGC
  if email.length == 0
    div = doc.css('.section-info')
      .css('.email')
      .drop_while { |d| d.text.strip.length == 0 }

    if div.length > 0
      matches =  div.first.text.match(email_regex)
      if matches != nil
        email = matches.string
      end
    end
  end

  {
    :agency_name => agency_title,
    :email => email
  }

end

if __FILE__ == $0
  # dl_pages()
  links = []
  folder_name = "./data/"
  for filename in Dir.entries(folder_name) do
    if filename.end_with?(".html")
      puts folder_name + filename
      file = File.open(folder_name + filename, "r")
      contents = file.read
      links += parse_page(filename.split(".").first, contents)
      file.close 
    end
  end

  File.open('output.txt', 'w') do |file|
    # file.write @string
    links.each_with_index do |link, i|
      # if i > 1
      #   break
      # end
      # contents = fetch(BASE_URL + link)
      dict = crawl_page_for_email(BASE_URL + link)
      file.puts link 
      file.puts "#{dict[:agency_name]}; #{dict[:email]}"
    end
  end
  
  # persist_html('wsg', fetch('https://www.gov.sg/sgdi/ministries/mom/statutory-boards/wsg'))
  # persist_html('agc', fetch('https://www.gov.sg/sgdi/organs-of-state/agc'))
  # file = File.open('./test/agc.html', 'r')
  # contents = file.read
  # puts crawl_for_email(contents)
  # file.close
end

