module HttpFetchable
  HTTP_TIMEOUT = 5

  module_function

  def http_get(url)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: HTTP_TIMEOUT, read_timeout: HTTP_TIMEOUT) { |http|
      http.get(uri.request_uri)
    }.body
  end
end
