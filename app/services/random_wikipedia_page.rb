# Fetches a random article from the Wikipedia API and exposes the pieces of it
# a Record needs: a cleaned-up band name and a permalink.
class RandomWikipediaPage
  include Callable
  include HttpFetchable

  API_URL = "https://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=1&rnnamespace=0&format=json"

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
    article = JSON.parse(http_get(API_URL))["query"]["random"].first

    Page.new(id: article["id"], title: article["title"])
  end
end
