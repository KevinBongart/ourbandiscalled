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
    response = Net::HTTP.get URI(url)
    json = JSON.parse response
    title = json["query"]["random"].first["title"]

    band_name = title.gsub(/ \(.*\)$/, '')
    band_name = band_name.titleize

    self.band = band_name
    self.wikipedia_url = "http://en.wikipedia.org/wiki/#{title.gsub(/ /, '_')}"
  end

  def set_album_name
    url = "https://www.quotationspage.com/random.php"
    response = Net::HTTP.get URI(url)
    body = Nokogiri::HTML response

    last_quote = body.search("dt[@class*=quote]").last.search("a").first
    quote = last_quote.inner_html
    quote.force_encoding(Encoding::UTF_8)

    last_words = quote.split(/ /)
    last_words = last_words.last(4)
    last_words.last.gsub!(/\./, '')

    album_name = last_words.join(" ")
    album_name = album_name.titleize

    self.title = album_name
    self.quotationspage_url = "https://www.quotationspage.com/#{last_quote.attributes['href'].value}"
  end

  def set_album_cover
    url = "https://www.flickr.com/explore"
    response = Net::HTTP.get URI(url)
    body = Nokogiri::HTML response
    photo_urls = body.search('.photo-list-photo-container img').map { |img| img['src'] }

    album_cover = "https:#{photo_urls.sample}"

    self.cover = album_cover
    self.flickr_url = "http://flickr.com/photo.gne?id=#{album_cover.split('/')[4].split('_')[0]}"
  end

  def set_slug
    self.slug = "#{title.parameterize}-by-#{band.parameterize}"
  end
end
