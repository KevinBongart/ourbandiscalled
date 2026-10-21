require "rails_helper"

RSpec.describe Record do
  before do
    stub_next_quote
    stub_wikipedia
    stub_flickr
  end

  describe "#generate_content" do
    it "populates all fields on create" do
      record = Record.create

      expect(record.band).to be_present
      expect(record.wikipedia_url).to be_present
      expect(record.title).to be_present
      expect(record.quotationspage_url).to be_present
      expect(record.cover).to be_present
      expect(record.flickr_url).to be_present
      expect(record.slug).to be_present
    end

    it "derives the slug from the album title and band" do
      stub_next_quote(body: "Nothing beats a great pair of shoes.")
      stub_wikipedia(title: "Test Band")

      record = Record.create

      expect(record.title).to eq("Great Pair Of Shoes")
      expect(record.band).to eq("Test Band")
      expect(record.slug).to eq("great-pair-of-shoes-by-test-band")
    end

    it "records a timing for each external call" do
      record = Record.create

      expect(record.timings.keys).to contain_exactly("Wikipedia", "Quote", "Flickr")
    end

    it "starts with no views" do
      expect(Record.create.views).to eq(0)
    end

    it "only fetches Flickr once when creating two records" do
      stub_wikipedia(pages: [ { id: 1, title: "Test Band" }, { id: 2, title: "Other Band" } ])

      Record.create
      Record.create

      expect(WebMock).to have_requested(:get, RandomFlickrPhoto::EXPLORE_URL).once
    end
  end

  describe "#to_param" do
    it "is the slug, so URLs read as the album" do
      record = Record.create

      expect(record.to_param).to eq(record.slug)
    end
  end
end
