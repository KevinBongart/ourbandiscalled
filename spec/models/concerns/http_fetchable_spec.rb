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
      stub_request(:get, "https://example.org/limited")
        .to_return(status: 429, body: "<!DOCTYPE html>", headers: { "Retry-After" => "35" })

      expect { client.send(:http_get, "https://example.org/limited") }
        .to raise_error(Faraday::TooManyRequestsError)
    end

    it "carries the status and headers on the error" do
      stub_request(:get, "https://example.org/limited")
        .to_return(status: 429, headers: { "Retry-After" => "35" })

      client.send(:http_get, "https://example.org/limited")
    rescue Faraday::Error => error
      expect(error.response[:status]).to eq(429)
      expect(error.response[:headers]["retry-after"]).to eq("35")
    end

    it "raises a not-found error for a 404" do
      stub_request(:get, "https://example.org/missing").to_return(status: 404)

      expect { client.send(:http_get, "https://example.org/missing") }
        .to raise_error(Faraday::ResourceNotFound)
    end

    it "retries a transient server error and returns the retry's body" do
      stub_request(:get, "https://example.org/flaky")
        .to_return({ status: 503, body: "<!DOCTYPE html>" }, { status: 200, body: "recovered" })

      expect(client.send(:http_get, "https://example.org/flaky")).to eq("recovered")
      expect(WebMock).to have_requested(:get, "https://example.org/flaky").twice
    end

    it "gives up after the retry rather than retrying forever" do
      stub_request(:get, "https://example.org/down").to_return(status: 503)

      expect { client.send(:http_get, "https://example.org/down") }.to raise_error(Faraday::ServerError)
      expect(WebMock).to have_requested(:get, "https://example.org/down").twice
    end

    it "does not retry a rate limit, which an immediate retry cannot clear" do
      stub_request(:get, "https://example.org/limited")
        .to_return(status: 429, headers: { "Retry-After" => "35" })

      expect { client.send(:http_get, "https://example.org/limited") }.to raise_error(Faraday::TooManyRequestsError)
      expect(WebMock).to have_requested(:get, "https://example.org/limited").once
    end

    it "does not retry a client error" do
      stub_request(:get, "https://example.org/missing").to_return(status: 404)

      expect { client.send(:http_get, "https://example.org/missing") }.to raise_error(Faraday::ResourceNotFound)
      expect(WebMock).to have_requested(:get, "https://example.org/missing").once
    end

    it "follows a redirect instead of returning its body" do
      stub_request(:get, "https://example.org/old")
        .to_return(status: 302, body: "<html>moved</html>", headers: { "Location" => "https://example.org/new" })
      stub_request(:get, "https://example.org/new").to_return(status: 200, body: "payload")

      expect(client.send(:http_get, "https://example.org/old")).to eq("payload")
    end

    it "stops after too many redirects" do
      stub_request(:get, "https://example.org/loop")
        .to_return(status: 302, headers: { "Location" => "https://example.org/loop" })

      expect { client.send(:http_get, "https://example.org/loop") }
        .to raise_error(Faraday::FollowRedirects::RedirectLimitReached)
    end

    it "propagates timeouts rather than swallowing them" do
      stub_request(:get, "https://example.org/slow").to_timeout

      expect { client.send(:http_get, "https://example.org/slow") }.to raise_error(Faraday::ConnectionFailed)
      expect(WebMock).to have_requested(:get, "https://example.org/slow").once
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
