class Record < ActiveRecord::Base
  require 'open-uri'

  before_create :set_band_name
  before_create :set_album_name
  before_create :set_album_cover
  before_create :set_slug

  def to_param
    slug
  end

  private

  def set_band_name
    url = "https://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=1&rnnamespace=0&format=json"
    json = JSON.parse open(url).read
    title = json["query"]["random"].first["title"]

    band_name = title.gsub(/ \(.*\)$/, '')
    band_name = band_name.titleize

    self.band = band_name
    self.wikipedia_url = "http://en.wikipedia.org/wiki/#{title.gsub(/ /, '_')}"
  end

  def set_album_name
    url = "http://www.quotationspage.com/random.php3"
    body = Nokogiri::HTML(open(url))
    last_quote = body.search("dt[@class*=quote]").last.search("a").first

    quote = last_quote.inner_html
    last_words = quote.split(/ /)
    last_words = last_words.last(4)
    last_words.last.gsub!(/\./, '')
    album_name = last_words.join(" ")
    album_name = album_name.titleize

    self.title = album_name
    self.quotationspage_url = "http://www.quotationspage.com/#{last_quote.attributes['href'].value}"
  end

  def set_album_cover
    url = "https://www.flickr.com/explore/interesting/7days/"
    body = Nokogiri::HTML(open(url))
    third_photo = body.css("span.photo_container.pc_m")[2].at("a")

    album_cover = third_photo.at("img")
    album_cover = album_cover.attributes["src"].value

    self.cover = album_cover
    self.flickr_url = "http://www.flickr.com#{third_photo.attributes['href'].value}"
  end

  def set_slug
    self.slug = "#{title.parameterize}-by-#{band.parameterize}"
  end
end
