require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require 'net/http'
require 'json'
require 'hpricot'
require 'rest-open-uri'
require 'sinatra/base'

set :public, File.dirname(__FILE__) + '/public'

def get_http(url)
  url = URI.parse(url)
  req = Net::HTTP::Get.new(url.path)

  Net::HTTP.start(url.host, url.port) {|http| http.request(req)}
end

def get_band_name
  pages = 1 + rand(10)
  puts pages.to_s
  res = get_http('http://www.wikirandom.org/json&pages=' + pages.to_s)
  json = JSON.parse res.body
  band_name = json['data'][rand(pages)]['title']

  band_name.gsub(/ \(.*\)$/, '')
end

def get_album_name
  res = get_http('http://www.quotationspage.com/random.php3')
  body = Hpricot res.body
  quote = body.search("dt[@class*=quote]").last.search("a").first.inner_html
  last_words = quote.split(/ /)
  last_words = last_words.last(4)
  last_words.first.capitalize!
  last_words.last.gsub!(/\./, '')

  last_words.join(" ")
end

def get_album_cover
  res = get_http('http://www.flickr.com/explore/interesting/7days/')
  body = Hpricot res.body
  a = body.search("span[@class*=photo_container pc_m]")[2].at("a")
  album_cover = a.at("img")

  url = a.attributes["href"]
  album_cover = album_cover.attributes["src"]

  {"album_cover" => album_cover, "url" => url}
end

get '/' do
  @band_name    = get_band_name
  @album_name   = get_album_name
  cover         = get_album_cover
  @album_cover  = cover["album_cover"]
  @url          = cover["url"]

  erb :hello
end
