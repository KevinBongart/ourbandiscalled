class Record < ActiveRecord::Base
  FLICKR_CACHE_KEY = "flickr_photos"

  attr_accessor :timings

  before_create :generate_content

  def to_param
    slug
  end

  private

  def generate_content
    @timings = {}

    threads = [
      Thread.new { timed("Wikipedia") { set_band_name } },
      Thread.new { timed("Quote") { set_album_name } },
      Thread.new { timed("Flickr") { set_album_cover } }
    ]
    threads.each(&:join)

    set_slug
  end

  def timed(label)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @timings[label] = elapsed
    Rails.logger.info("[#{label}] #{(elapsed * 1000).round}ms")
  end

  def set_band_name
    uri = URI("https://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=1&rnnamespace=0&format=json")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) { |http| http.get(uri.request_uri) }.body
    json = JSON.parse response
    page = json["query"]["random"].first

    self.band = page["title"].gsub(/ \(.*\)$/, "").titleize
    self.wikipedia_url = "https://en.wikipedia.org/wiki/?curid=#{page["id"]}"
  end

  def set_album_name
    quote = Quote.next!
    last_words = quote.body.split(" ").last(4)
    last_words.last.gsub!(/\./, "")
    self.title = last_words.join(" ").titleize
    self.quotationspage_url = quote.url
  end

  def set_album_cover
    Rails.logger.info("[Flickr] cache: #{Rails.cache.exist?(FLICKR_CACHE_KEY) ? "hit" : "miss"}")
    photo_urls = Rails.cache.fetch(FLICKR_CACHE_KEY, expires_in: 3.minutes) do
      uri = URI("https://www.flickr.com/explore")
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) { |http| http.get(uri.request_uri) }.body
      body = Nokogiri::HTML response
      body.search(".photo-list-photo-container img").map { |img| img["src"] }
    end

    album_cover = "https:#{photo_urls.sample}"

    self.cover = album_cover
    self.flickr_url = "http://flickr.com/photo.gne?id=#{album_cover.split('/')[4].split('_')[0]}"
  end

  def set_slug
    self.slug = "#{title.parameterize}-by-#{band.parameterize}"
  end
end
