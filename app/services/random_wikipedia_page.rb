# Fetches random articles from the Wikipedia API and exposes the pieces of one
# a Record needs: a cleaned-up band name and a permalink.
#
# Articles are fetched BATCH_SIZE at a time and handed out one per record. The
# API costs the same for 20 articles as for 1, and Wikimedia rate-limits hard
# -- a burst of single-article requests earns a 429 with "retry-after: 35".
class RandomWikipediaPage
  include Callable
  include HttpFetchable

  class UnexpectedResponse < StandardError; end

  BATCH_SIZE = 20
  CACHE_KEY = "wikipedia_pages"
  CACHE_TTL = 1.hour
  API_URL = "https://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=#{BATCH_SIZE}&rnnamespace=0&format=json"

  Page = Data.define(:id, :title) do
    # Wikipedia disambiguates articles with a trailing parenthetical, e.g.
    # "Mercury (element)". Bands rarely do.
    def band_name
      title.gsub(/ \(.*\)$/, "").titleize
    end

    def url
      "https://en.wikipedia.org/wiki/?curid=#{id}"
    end
  end

  def call
    article = next_article

    Page.new(id: article[:id], title: article[:title])
  end

  private

  # Deliberately unsynchronised. Two concurrent builds can at worst hand out
  # the same article or both refill, costing a repeated band name or one spare
  # API call. A lock would have to be held across the fetch below, serialising
  # every concurrent record behind one HTTP call, and would not help across
  # processes anyway.
  def next_article
    pending = Rails.cache.read(CACHE_KEY).presence || fetch_batch
    article = pending.shift
    Rails.cache.write(CACHE_KEY, pending, expires_in: CACHE_TTL)

    article
  end

  def fetch_batch
    Rails.logger.info("[Wikipedia] pool miss -- fetching #{BATCH_SIZE} articles")

    parse(http_get(API_URL))["query"]["random"].map do |article|
      { id: article["id"], title: article["title"] }
    end
  end

  # Wikipedia can answer 200 with an HTML interstitial. Say so plainly rather
  # than surfacing "unexpected character: '<!DOCTYPE'" from deep in the parser.
  def parse(body)
    JSON.parse(body)
  rescue JSON::ParserError
    raise UnexpectedResponse, "Wikipedia returned a non-JSON response: #{body.to_s.truncate(200).inspect}"
  end
end
