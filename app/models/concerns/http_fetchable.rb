module HttpFetchable
  HTTP_TIMEOUT = 5
  MAX_REDIRECTS = 3
  MAX_RETRIES = 1
  RETRY_DELAY = 0.1

  # Wikimedia asks API clients to identify themselves and throttles generic
  # agents harder than named ones. Faraday would otherwise send its own.
  # https://meta.wikimedia.org/wiki/User-Agent_policy
  USER_AGENT = "OurBandIsCalled/1.0 (+https://github.com/KevinBongart/ourbandiscalled)".freeze

  # Shared: a Faraday connection is safe to reuse across threads, and building
  # the middleware stack per call would be waste.
  #
  # `raise_error` is what matters here. Without it Faraday hands back the body
  # of any response, so an upstream error page reaches a caller expecting JSON
  # and a rate limit surfaces as an unreadable parser error.
  CONNECTION = Faraday.new(headers: { "User-Agent" => USER_AGENT }) do |faraday|
    # Outermost, so it retries the typed error raised below it. Only 5xx
    # qualifies: a 429 raises Faraday::TooManyRequestsError (a client error)
    # and Wikimedia pairs it with "retry-after: 35", so an immediate retry
    # cannot succeed and would only add to the load that caused the throttling.
    # Timeouts surface as Faraday::ConnectionFailed and are excluded too -- one
    # has already cost HTTP_TIMEOUT seconds, and records are generated inside
    # the request, so retrying would double the worst case a visitor waits.
    faraday.request :retry, max: MAX_RETRIES, interval: RETRY_DELAY, exceptions: [ Faraday::ServerError ]
    faraday.response :raise_error
    faraday.response :follow_redirects, limit: MAX_REDIRECTS
    faraday.options.timeout = HTTP_TIMEOUT
    faraday.options.open_timeout = HTTP_TIMEOUT
  end

  module_function

  def http_get(url)
    CONNECTION.get(url).body
  end
end
