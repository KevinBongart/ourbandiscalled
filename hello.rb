require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require 'net/http'
require 'json'
require 'hpricot'
require 'rest-open-uri'

def get_http(url)
  url = URI.parse(url)
  req = Net::HTTP::Get.new(url.request_uri, "User-Agent" => "ourbandiscalled")
  Net::HTTP.start(url.host, url.port) {|http| http.request(req)}
end

def get_band_name
  res = get_http('http://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=1&rnnamespace=0&format=json')
  json = JSON.parse res.body
  band_name = json['query']['random'].first['title']
  url = 'http://en.wikipedia.org/wiki/' + band_name.gsub(/ /, '_')
  band_name.gsub!(/ \(.*\)$/, '')

  {"band_name" => band_name, "url" => url}
end

def get_album_name
  res = get_http('http://www.quotationspage.com/random.php3')
  body = Hpricot res.body
  a = body.search("dt[@class*=quote]").last.search("a").first
  url = 'http://www.quotationspage.com/' + a.attributes["href"]
  quote = a.inner_html
  last_words = quote.split(/ /)
  last_words = last_words.last(4)
  last_words.first.capitalize!
  last_words.last.gsub!(/\./, '')
  album_name = last_words.join(" ")

  {"album_name" => album_name, "url" => url}
end

def get_album_cover
  res = get_http('http://www.flickr.com/explore/interesting/7days/')
  body = Hpricot res.body
  a = body.search("span[@class*=photo_container pc_m]")[2].at("a")
  album_cover = a.at("img")
  url = 'http://www.flickr.com' + a.attributes["href"]
  album_cover = album_cover.attributes["src"]

  {"album_cover" => album_cover, "url" => url}
end

get '/' do
  @band_name        = get_band_name
  @band_name_url    = @band_name["url"]
  @band_name        = @band_name["band_name"]

  @album_name       = get_album_name
  @album_name_url   = @album_name["url"]
  @album_name       = @album_name["album_name"]

  @cover            = get_album_cover
  @album_cover      = @cover["album_cover"]
  @album_cover_url  = @cover["url"]

  erb :hello
end
