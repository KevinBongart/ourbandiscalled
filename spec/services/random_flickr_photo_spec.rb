require "rails_helper"

RSpec.describe RandomFlickrPhoto do
  let(:explore_html) do
    <<~HTML
      <html><body>
        <div class="photo-list-photo-container">
          <img src="//live.staticflickr.com/65535/11111_aaaaa.jpg">
        </div>
        <div class="photo-list-photo-container">
          <img src="//live.staticflickr.com/65535/22222_bbbbb.jpg">
        </div>
      </body></html>
    HTML
  end

  before do
    stub_request(:get, RandomFlickrPhoto::EXPLORE_URL).to_return(status: 200, body: explore_html)
  end

  describe ".call" do
    it "returns one of the photos scraped from the Explore page" do
      photo = described_class.call

      expect(photo.image_url).to be_in([
        "https://live.staticflickr.com/65535/11111_aaaaa.jpg",
        "https://live.staticflickr.com/65535/22222_bbbbb.jpg"
      ])
    end

    it "scrapes the Explore page only once across calls" do
      3.times { described_class.call }

      expect(WebMock).to have_requested(:get, RandomFlickrPhoto::EXPLORE_URL).once
    end

    it "scrapes again once the cache has expired" do
      described_class.call
      travel_to(RandomFlickrPhoto::CACHE_TTL.from_now + 1.second) { described_class.call }

      expect(WebMock).to have_requested(:get, RandomFlickrPhoto::EXPLORE_URL).twice
    end
  end

  describe RandomFlickrPhoto::Photo do
    describe "#page_url" do
      it "derives the photo id from the static URL" do
        photo = described_class.new(image_url: "https://live.staticflickr.com/65535/12345_abcde.jpg")

        expect(photo.page_url).to eq("http://flickr.com/photo.gne?id=12345")
      end
    end
  end
end
