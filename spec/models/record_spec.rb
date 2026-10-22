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

    it "only fetches Flickr once when creating two records" do
      stub_wikipedia(pages: [ { id: 1, title: "Test Band" }, { id: 2, title: "Other Band" } ])

      Record.create
      Record.create

      expect(WebMock).to have_requested(:get, RandomFlickrPhoto::EXPLORE_URL).once
    end
  end
end
