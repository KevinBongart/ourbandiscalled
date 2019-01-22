require "rails_helper"

RSpec.describe "root", :vcr do
  subject { get('/') }

  it "creates a new album" do
    expect(Record.count).to eq(0)

    subject

    expect(Record.count).to eq(1)
    record = Record.first

    expect(record.band).to eq 'Luigi Turci'
    expect(record.wikipedia_url).to eq 'http://en.wikipedia.org/wiki/Luigi_Turci'

    expect(record.title).to eq 'Remember To Get Happy'
    expect(record.quotationspage_url).to eq 'http://www.quotationspage.com//quote/41771.html'

    expect(record.cover).to eq 'https://farm5.staticflickr.com/4913/46097806904_98bcbf9e0a_m.jpg'
    expect(record.flickr_url).to eq 'http://www.flickr.com/photos/ishootbirds/46097806904/'

    expect(record.slug).to eq 'remember-to-get-happy-by-luigi-turci'
    expect(record.views).to eq 0
  end

  it 'redirects to the album page' do
    subject

    expect(response).to redirect_to('http://www.example.com/in-our-own-image-by-luis-rosa')
    follow_redirect!

    expect(response.body).to include('In Our Own Image')
    expect(response.body).to include('Luis Rosa')
  end
end
