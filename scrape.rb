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
  IO.write("./data/" + name + ".html", contents)
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

def crawl_for_email(url)
  contents = fetch(url)
  doc = Nokogiri::HTML(contents)
  agency_title = doc.css(".agency-title")
    .css("h1")
    .first
    .text
  addr = doc.css("address")
  email = addr.css("a")
      .map { |a| a.text }
      .select { |text| text.match(/@[A-Za-z]+.gov.sg/) }
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

  links.each_with_index do |link, i|
    # if i > 2
    #   break
    # end
    puts link
    # contents = fetch(BASE_URL + link)
    puts crawl_for_email(BASE_URL + link)
  end
end
