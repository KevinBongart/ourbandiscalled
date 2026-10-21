# Draws a quote from the pool and turns it into the album title.
class RandomQuote
  # Bill Harris' algorithm takes the tail end of the quote as the title.
  WORD_COUNT = 4

  Quotation = Data.define(:body, :url) do
    def album_title
      words = body.to_s.split(" ").last(WORD_COUNT)
      return "" if words.empty?

      # Only the final word can carry the sentence's full stop.
      words = words[0..-2] + [ words.last.delete(".") ]
      words.join(" ").titleize
    end
  end

  def self.call
    new.call
  end

  def call
    quote = Quote.next!

    Quotation.new(body: quote.body, url: quote.url)
  end
end
