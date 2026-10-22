require "rails_helper"

RSpec.describe HttpFetchable do
  let(:client) { Class.new { include HttpFetchable }.new }

  describe "#http_get" do
    it "returns the response body" do
      stub_request(:get, "https://example.org/thing").to_return(status: 200, body: "payload")

      expect(client.send(:http_get, "https://example.org/thing")).to eq("payload")
    end

    it "requests the full path including the query string" do
      stub_request(:get, "https://example.org/search?q=ruby&page=2").to_return(status: 200, body: "ok")

      client.send(:http_get, "https://example.org/search?q=ruby&page=2")

      expect(WebMock).to have_requested(:get, "https://example.org/search?q=ruby&page=2")
    end

    it "returns the body even for error statuses" do
      stub_request(:get, "https://example.org/missing").to_return(status: 404, body: "not found")

      expect(client.send(:http_get, "https://example.org/missing")).to eq("not found")
    end

    it "propagates timeouts rather than swallowing them" do
      stub_request(:get, "https://example.org/slow").to_timeout

      expect { client.send(:http_get, "https://example.org/slow") }.to raise_error(Net::OpenTimeout)
    end

    it "is also available as a module function" do
      stub_request(:get, "https://example.org/direct").to_return(status: 200, body: "direct")

      expect(HttpFetchable.http_get("https://example.org/direct")).to eq("direct")
    end
  end
end
