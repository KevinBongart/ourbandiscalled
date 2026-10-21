require "rails_helper"

RSpec.describe RandomWikipediaPage do
  describe ".call" do
    it "returns a page built from the API response" do
      stub_wikipedia(id: 42, title: "Test Band")

      page = described_class.call

      expect(page.id).to eq(42)
      expect(page.title).to eq("Test Band")
    end

    it "requests a single random article from the main namespace" do
      stub_wikipedia(id: 1, title: "Anything")

      described_class.call

      expect(WebMock).to have_requested(:get, described_class::API_URL)
    end
  end

  describe RandomWikipediaPage::Page do
    describe "#band_name" do
      it "titleizes the article title" do
        expect(described_class.new(id: 1, title: "the velvet sound").band_name).to eq("The Velvet Sound")
      end

      it "drops a trailing disambiguation parenthetical" do
        expect(described_class.new(id: 1, title: "Mercury (element)").band_name).to eq("Mercury")
      end

      it "keeps parentheses that are not at the end" do
        expect(described_class.new(id: 1, title: "Sigur (Ros) Band").band_name).to eq("Sigur (Ros) Band")
      end
    end

    describe "#url" do
      it "builds a curid permalink" do
        expect(described_class.new(id: 123, title: "X").url).to eq("https://en.wikipedia.org/wiki/?curid=123")
      end
    end
  end
end
