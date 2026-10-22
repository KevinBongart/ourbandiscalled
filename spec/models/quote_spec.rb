require "rails_helper"

RSpec.describe Quote do
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

  describe ".unused" do
    it "excludes quotes that have been used" do
      unused = Quote.create!(body: "Fresh", author: "A", source_id: 1, url: "https://x.com/1")
      Quote.create!(body: "Spent", author: "B", source_id: 2, url: "https://x.com/2", used_at: 1.hour.ago)

      expect(Quote.unused).to contain_exactly(unused)
    end
  end

  describe "#used!" do
    it "stamps used_at" do
      quote = Quote.create!(body: "Fresh", author: "A", source_id: 1, url: "https://x.com/1")

      expect { quote.used! }.to change { quote.reload.used_at }.from(nil)
    end

    it "removes the quote from the unused pool" do
      quote = Quote.create!(body: "Fresh", author: "A", source_id: 1, url: "https://x.com/1")

      quote.used!

      expect(Quote.unused).to be_empty
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

      it "does not fetch more quotes" do
        expect(FetchQuotes).not_to receive(:call)
        Quote.next!
      end
    end

    context "with fewer than 20 unused quotes" do
      before do
        create_quotes(5)
        stub_quotations_page
      end

      it "fetches more quotes" do
        expect(FetchQuotes).to receive(:call).and_call_original
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
        stub_quotations_page(quotations: [])
      end

      it "raises when no quotes can be found or fetched" do
        expect { Quote.next! }.to raise_error(RuntimeError, "Quote pool is empty and could not fetch more quotes")
      end
    end
  end
end

RSpec.describe FetchQuotes do
  before do
    stub_quotations_page
  end

  describe ".call" do
    it "inserts quotes parsed from the page" do
      expect { FetchQuotes.call }.to change(Quote, :count).by(3)

      quote = Quote.find_by(source_id: 100)
      expect(quote.body).to eq("First quote text.")
      expect(quote.author).to eq("Author One")
      expect(quote.url).to eq("https://www.quotationspage.com/quote/100.html")
      expect(quote.used_at).to be_nil
    end

    it "skips quotes already in the database (deduplicates by source_id)" do
      Quote.create!(body: "Old text", author: "Author One", source_id: 100, url: "https://www.quotationspage.com/quote/100.html")
      expect { FetchQuotes.call }.to change(Quote, :count).by(2)
    end

    it "resets used_at to nil on all quotes when no new quotes are added" do
      Quote.create!(body: "First quote text.", author: "Author One", source_id: 100, url: "https://www.quotationspage.com/quote/100.html", used_at: 1.hour.ago)
      Quote.create!(body: "Second quote text here.", author: "Author Two", source_id: 200, url: "https://www.quotationspage.com/quote/200.html", used_at: 2.hours.ago)
      Quote.create!(body: "Third and final text.", author: "Author Three", source_id: 300, url: "https://www.quotationspage.com/quote/300.html", used_at: 3.hours.ago)

      expect { FetchQuotes.call }.not_to change(Quote, :count)
      expect(Quote.where(used_at: nil).count).to eq(3)
    end
  end
end
