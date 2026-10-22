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

    it "raises rather than returning an upstream error page as data" do
      stub_request(:get, "https://example.org/limited").to_return(status: 429, body: "<!DOCTYPE html>")

      expect { client.send(:http_get, "https://example.org/limited") }
        .to raise_error(HttpFetchable::ResponseError, %r{GET https://example.org/limited returned 429})
    end

    it "exposes the status on the error" do
      stub_request(:get, "https://example.org/missing").to_return(status: 404)

      client.send(:http_get, "https://example.org/missing")
    rescue HttpFetchable::ResponseError => error
      expect(error.status).to eq(404)
    end

    it "treats a redirect as unsuccessful rather than returning its body" do
      stub_request(:get, "https://example.org/old")
        .to_return(status: 302, body: "", headers: { "Location" => "https://example.org/new" })

      expect { client.send(:http_get, "https://example.org/old") }.to raise_error(HttpFetchable::ResponseError)
    end

    it "propagates timeouts rather than swallowing them" do
      stub_request(:get, "https://example.org/slow").to_timeout

      expect { client.send(:http_get, "https://example.org/slow") }.to raise_error(Net::OpenTimeout)
    end

    it "identifies itself with a descriptive User-Agent" do
      stub_request(:get, "https://example.org/thing").to_return(status: 200, body: "ok")

      client.send(:http_get, "https://example.org/thing")

      expect(WebMock).to have_requested(:get, "https://example.org/thing")
        .with(headers: { "User-Agent" => HttpFetchable::USER_AGENT })
    end

    it "is also available as a module function" do
      stub_request(:get, "https://example.org/direct").to_return(status: 200, body: "direct")

      expect(HttpFetchable.http_get("https://example.org/direct")).to eq("direct")
    end
  end
end
