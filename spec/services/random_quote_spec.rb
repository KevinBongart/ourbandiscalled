require "rails_helper"

RSpec.describe RandomQuote do
  describe ".call" do
    it "returns a quotation built from the next quote in the pool" do
      stub_next_quote(body: "Nothing beats a great pair of shoes.")

      quotation = described_class.call

      expect(quotation.body).to eq("Nothing beats a great pair of shoes.")
      expect(quotation.url).to eq("https://www.quotationspage.com/quote/42.html")
    end

    it "draws from the real pool, marking the quote used" do
      quote = Quote.create!(
        body: "To be or not to be.",
        author: "Shakespeare",
        source_id: 42,
        url: "https://www.quotationspage.com/quote/42.html"
      )
      # The pool sits under its refill threshold with a single quote; refilling
      # is FetchQuotes' job and has its own specs.
      allow(FetchQuotes).to receive(:call)

      quotation = described_class.call

      expect(quotation.url).to eq(quote.url)
      expect(quote.reload.used_at).to be_present
    end
  end

  describe RandomQuote::Quotation do
    def title_for(body)
      described_class.new(body: body, url: "https://example.com").album_title
    end

    it "titleizes the last four words of the quote" do
      expect(title_for("Sample quote with enough words here.")).to eq("With Enough Words Here")
    end

    it "strips the trailing full stop from the final word" do
      expect(title_for("a b c done.")).to eq("A B C Done")
    end

    it "keeps full stops inside earlier words" do
      expect(title_for("He met Dr. Smith today.")).to eq("Met Dr. Smith Today")
    end

    it "uses every word when the quote is shorter than four words" do
      expect(title_for("Two words.")).to eq("Two Words")
    end

    it "takes only the last four words of a longer quote" do
      expect(title_for("a b c d e f")).to eq("C D E F")
    end

    it "returns an empty string for an empty quote" do
      expect(title_for("")).to eq("")
    end

    it "returns an empty string for a nil quote" do
      expect(title_for(nil)).to eq("")
    end
  end
end
