require "rails_helper"

RSpec.describe Quote do
  let(:quotations_page_html) do
    <<~HTML
      <html><body><dl>
        <dt class="quote"><a href="/quote/100.html">First quote text.</a></dt>
        <dd class="author"><div class="icons"></div><b><a href="/quotes/Author_One/">Author One</a></b></dd>
        <dt class="quote"><a href="/quote/200.html">Second quote text here.</a></dt>
        <dd class="author"><div class="icons"></div><b><a href="/quotes/Author_Two/">Author Two</a> (1900 - 1980)</b></dd>
        <dt class="quote"><a href="/quote/300.html">Third and final text.</a></dt>
        <dd class="author"><div class="icons"></div><b><a href="/quotes/Author_Three/">Author Three</a></b></dd>
      </dl></body></html>
    HTML
  end

  describe "validations" do
    it "is valid with all required fields" do
      quote = Quote.new(
        body: "To be or not to be.",
        author: "Shakespeare",
        source_id: 42,
        url: "https://www.quotationspage.com/quote/42.html"
      )
      expect(quote).to be_valid
    end

    it "is invalid without body" do
      expect(Quote.new(author: "A", source_id: 1, url: "https://x.com")).not_to be_valid
    end

    it "is valid without author" do
      expect(Quote.new(body: "A quote", source_id: 1, url: "https://x.com")).to be_valid
    end

    it "is invalid without source_id" do
      expect(Quote.new(body: "A quote", author: "A", url: "https://x.com")).not_to be_valid
    end

    it "is invalid without url" do
      expect(Quote.new(body: "A quote", author: "A", source_id: 1)).not_to be_valid
    end

    it "is invalid with a duplicate source_id" do
      Quote.create!(body: "First", author: "A", source_id: 99, url: "https://www.quotationspage.com/quote/99.html")
      duplicate = Quote.new(body: "Second", author: "B", source_id: 99, url: "https://www.quotationspage.com/quote/99.html")
      expect(duplicate).not_to be_valid
    end
  end

  describe ".fetch_more_random_quotes" do
    before do
      stub_request(:get, "https://www.quotationspage.com/random.php")
        .to_return(body: quotations_page_html, status: 200)
    end

    it "inserts quotes parsed from the page" do
      expect { Quote.fetch_more_random_quotes }.to change(Quote, :count).by(3)

      quote = Quote.find_by(source_id: 100)
      expect(quote.body).to eq("First quote text.")
      expect(quote.author).to eq("Author One")
      expect(quote.url).to eq("https://www.quotationspage.com/quote/100.html")
      expect(quote.used_at).to be_nil
    end

    it "skips quotes already in the database (deduplicates by source_id)" do
      Quote.create!(body: "Old text", author: "Author One", source_id: 100, url: "https://www.quotationspage.com/quote/100.html")
      expect { Quote.fetch_more_random_quotes }.to change(Quote, :count).by(2)
    end

    it "resets used_at to nil on all quotes when no new quotes are added" do
      Quote.create!(body: "First quote text.", author: "Author One", source_id: 100, url: "https://www.quotationspage.com/quote/100.html", used_at: 1.hour.ago)
      Quote.create!(body: "Second quote text here.", author: "Author Two", source_id: 200, url: "https://www.quotationspage.com/quote/200.html", used_at: 2.hours.ago)
      Quote.create!(body: "Third and final text.", author: "Author Three", source_id: 300, url: "https://www.quotationspage.com/quote/300.html", used_at: 3.hours.ago)

      expect { Quote.fetch_more_random_quotes }.not_to change(Quote, :count)
      expect(Quote.where(used_at: nil).count).to eq(3)
    end
  end

  describe ".next!" do
    def create_quotes(count, used: false)
      count.times do |i|
        Quote.create!(
          body: "Quote number #{i}",
          author: "Author #{i}",
          source_id: i + 1,
          url: "https://www.quotationspage.com/quote/#{i + 1}.html",
          used_at: used ? i.hours.ago : nil
        )
      end
    end

    context "with 20 or more unused quotes in the database" do
      before { create_quotes(25) }

      it "returns a Quote instance" do
        expect(Quote.next!).to be_a(Quote)
      end

      it "marks the returned quote as used" do
        quote = Quote.next!
        expect(quote.reload.used_at).to be_present
      end

      it "does not call fetch_more_random_quotes" do
        expect(Quote).not_to receive(:fetch_more_random_quotes)
        Quote.next!
      end
    end

    context "with fewer than 20 unused quotes" do
      before do
        create_quotes(5)
        stub_request(:get, "https://www.quotationspage.com/random.php")
          .to_return(body: quotations_page_html, status: 200)
      end

      it "calls fetch_more_random_quotes" do
        expect(Quote).to receive(:fetch_more_random_quotes).and_call_original
        Quote.next!
      end

      it "returns a quote after fetching more" do
        quote = Quote.next!
        expect(quote).to be_a(Quote)
        expect(quote.reload.used_at).to be_present
      end
    end

    context "with an empty database and a failed scrape" do
      before do
        stub_request(:get, "https://www.quotationspage.com/random.php")
          .to_return(body: "<html><body><dl></dl></body></html>", status: 200)
      end

      it "raises when no quotes can be found or fetched" do
        expect { Quote.next! }.to raise_error(RuntimeError, "Quote pool is empty and could not fetch more quotes")
      end
    end
  end
end
