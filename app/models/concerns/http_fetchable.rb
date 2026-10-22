module HttpFetchable
  HTTP_TIMEOUT = 5

  # Wikimedia asks API clients to identify themselves and throttles generic
  # agents harder than named ones. Net::HTTP would otherwise send "Ruby".
  # https://meta.wikimedia.org/wiki/User-Agent_policy
  USER_AGENT = "OurBandIsCalled/1.0 (+https://github.com/KevinBongart/ourbandiscalled)".freeze

  class ResponseError < StandardError
    attr_reader :status

    def initialize(url, status)
      @status = status
      super("GET #{url} returned #{status}")
    end
  end

  module_function

  # Returns a body only for a successful response. Upstream error pages are
  # HTML, and handing one to a caller that expects JSON turns a rate limit into
  # an unreadable parser error.
  def http_get(url)
    uri = URI(url)
    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      open_timeout: HTTP_TIMEOUT,
      read_timeout: HTTP_TIMEOUT
    ) { |http| http.get(uri.request_uri, "User-Agent" => USER_AGENT) }

    raise ResponseError.new(url, response.code.to_i) unless response.is_a?(Net::HTTPSuccess)

    response.body
  end
end
