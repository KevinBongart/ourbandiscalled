require "rails_helper"

RSpec.describe RandomWikipediaPage do
  describe ".call" do
    it "returns a page built from the API response" do
      stub_wikipedia(id: 42, title: "Test Band")

      page = described_class.call

      expect(page.id).to eq(42)
      expect(page.title).to eq("Test Band")
    end

    it "reports a non-JSON response clearly, with a preview of what came back" do
      stub_request(:get, RandomWikipediaPage::API_URL)
        .to_return(status: 200, body: "<!DOCTYPE html><html><body>Our servers are busy</body></html>")

      expect { described_class.call }.to raise_error(
        RandomWikipediaPage::UnexpectedResponse,
        /non-JSON response.*DOCTYPE/m
      )
    end

    it "surfaces an upstream error status rather than parsing the error page" do
      stub_request(:get, RandomWikipediaPage::API_URL).to_return(status: 503, body: "<!DOCTYPE html>")

      expect { described_class.call }.to raise_error(Faraday::ServerError)
    end

    it "requests random articles from the main namespace" do
      stub_wikipedia(id: 1, title: "Anything")

      described_class.call

      expect(WebMock).to have_requested(:get, described_class::API_URL)
    end

    it "asks for a whole batch in one request" do
      expect(described_class::API_URL).to include("rnlimit=#{described_class::BATCH_SIZE}")
    end

    it "serves a whole batch from a single request" do
      pages = (1..described_class::BATCH_SIZE).map { |n| { id: n, title: "Band #{n}" } }
      stub_wikipedia(pages: pages)

      titles = Array.new(described_class::BATCH_SIZE) { described_class.call.title }

      expect(titles).to eq(pages.map { |page| page[:title] })
      expect(WebMock).to have_requested(:get, described_class::API_URL).once
    end

    it "fetches another batch once the pool is drained" do
      stub_wikipedia(pages: [ { id: 1, title: "First" } ])

      described_class.call
      described_class.call

      expect(WebMock).to have_requested(:get, described_class::API_URL).twice
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
