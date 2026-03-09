require "rails_helper"

WIKIPEDIA_RESPONSE = '{"batchcomplete":"","query":{"random":[{"id":1,"ns":0,"title":"Test Band"}]}}'.freeze
FLICKR_HTML = <<~HTML.freeze
  <html><body>
    <div class="photo-list-photo-container">
      <img src="//live.staticflickr.com/65535/12345_abcde.jpg">
    </div>
  </body></html>
HTML

RSpec.describe Record do
  before do
    allow(Quote).to receive(:next!).and_return(
      double(
        body: "Sample quote with enough words here.",
        url: "https://www.quotationspage.com/quote/42.html"
      )
    )
    stub_request(:get, /en\.wikipedia\.org/).to_return(body: WIKIPEDIA_RESPONSE, status: 200)
    stub_request(:get, "https://www.flickr.com/explore").to_return(body: FLICKR_HTML, status: 200)
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
      allow(Net::HTTP).to receive(:get).and_call_original
      expect(Net::HTTP).to receive(:get).with(URI("https://www.flickr.com/explore")).once.and_call_original
      Record.create
      Record.create
    end
  end
end
