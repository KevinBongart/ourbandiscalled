# Scrapes Flickr's Explore page for photo URLs and picks one at random.
#
# The scraped list is cached, so bursts of records share a single request and
# still get different covers.
class RandomFlickrPhoto
  include Callable
  include HttpFetchable

  CACHE_KEY = "flickr_photos"
  CACHE_TTL = 3.minutes
  EXPLORE_URL = "https://www.flickr.com/explore"

  Photo = Data.define(:image_url) do
    # Turns "https://live.staticflickr.com/65535/12345_abcde.jpg" into the id
    # "12345", which is all flickr.com/photo.gne needs to resolve the page.
    def page_url
      "http://flickr.com/photo.gne?id=#{image_url.split("/")[4].split("_")[0]}"
    end
  end

  def call
    Photo.new(image_url: "https:#{photo_urls.sample}")
  end

  private

  def photo_urls
    Rails.logger.info("[Flickr] cache: #{Rails.cache.exist?(CACHE_KEY) ? "hit" : "miss"}")

    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      document = Nokogiri::HTML(http_get(EXPLORE_URL))
      document.search(".photo-list-photo-container img").map { |img| img["src"] }
    end
  end
end
