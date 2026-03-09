require 'rails_helper'

RSpec.describe Record do
  describe '#generate_content' do
    it 'populates all fields on create', :vcr do
      record = Record.create

      expect(record.band).to be_present
      expect(record.wikipedia_url).to be_present
      expect(record.title).to be_present
      expect(record.quotationspage_url).to be_present
      expect(record.cover).to be_present
      expect(record.flickr_url).to be_present
      expect(record.slug).to be_present
    end

    it 'only fetches Flickr once when creating two records', :vcr do
      allow(Net::HTTP).to receive(:get).and_call_original
      expect(Net::HTTP).to receive(:get).with(URI('https://www.flickr.com/explore')).once.and_call_original
      Record.create
      Record.create
    end
  end
end
