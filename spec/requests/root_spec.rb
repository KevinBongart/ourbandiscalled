require "rails_helper"

RSpec.describe "root", :vcr do
  before do
    allow(Quote).to receive(:next!).and_return(
      double(
        body: "Sample quote with enough words here.",
        url: "https://www.quotationspage.com/quote/42.html"
      )
    )
  end

  subject { get("/") }

  it "creates a new album" do
    expect(Record.count).to eq(0)

    subject

    expect(Record.count).to eq(1)
    record = Record.first

    expect(record.band).to be_present
    expect(record.wikipedia_url).to be_present

    expect(record.title).to be_present
    expect(record.quotationspage_url).to match(%r{https://www\.quotationspage\.com/quote/\d+\.html})

    expect(record.cover).to match(%r{https://live\.staticflickr\.com/})

    expect(record.flickr_url).to match(/http:\/\/flickr\.com\/photo\.gne\?id=\d+/)

    expect(record.slug).to be_present
    expect(record.views).to eq 0
  end

  it "redirects to the album page" do
    subject

    record = Record.first
    expect(response).to redirect_to("http://www.example.com/#{record.slug}")
    follow_redirect!

    expect(response.body).to include(record.title)
    expect(response.body).to include(record.band)
  end
end
