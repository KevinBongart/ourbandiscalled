# Shared WebMock stubs for the three external services a Record depends on.
# Keeping them in one place means a change to any upstream response shape is a
# single edit rather than a hunt through every spec that touches it.
module ExternalServiceStubs
  DEFAULT_PHOTO_PATH = "//live.staticflickr.com/65535/12345_abcde.jpg".freeze

  DEFAULT_QUOTATIONS = [
    { id: 100, text: "First quote text.", author: "Author One", lifespan: "" },
    { id: 200, text: "Second quote text here.", author: "Author Two", lifespan: " (1900 - 1980)" },
    { id: 300, text: "Third and final text.", author: "Author Three", lifespan: "" }
  ].freeze

  # Pass `pages:` to hand back a different article on each successive call --
  # records derive their slug from the band name, so two records created in one
  # example need two distinct titles.
  def stub_wikipedia(id: 1, title: "Test Band", pages: [ { id: id, title: title } ])
    responses = pages.map do |page|
      {
        status: 200,
        body: { batchcomplete: "", query: { random: [ { id: page[:id], ns: 0, title: page[:title] } ] } }.to_json
      }
    end

    stub_request(:get, RandomWikipediaPage::API_URL).to_return(*responses)
  end

  def stub_flickr(photo_paths: [ DEFAULT_PHOTO_PATH ])
    containers = photo_paths.map do |path|
      %(<div class="photo-list-photo-container"><img src="#{path}"></div>)
    end

    stub_request(:get, RandomFlickrPhoto::EXPLORE_URL).to_return(
      status: 200,
      body: "<html><body>#{containers.join}</body></html>"
    )
  end

  def stub_quotations_page(quotations: DEFAULT_QUOTATIONS)
    stub_request(:get, FetchQuotes::RANDOM_URL).to_return(
      status: 200,
      body: quotations_page_html(quotations)
    )
  end

  # Mirrors quotationspage.com's markup: a <dt> per quote, each followed by a
  # <dd> carrying the author.
  def quotations_page_html(quotations = DEFAULT_QUOTATIONS)
    rows = quotations.map do |quotation|
      <<~HTML
        <dt class="quote"><a href="/quote/#{quotation[:id]}.html">#{quotation[:text]}</a></dt>
        <dd class="author"><div class="icons"></div><b><a href="/quotes/#{quotation[:author].tr(" ", "_")}/">#{quotation[:author]}</a>#{quotation[:lifespan]}</b></dd>
      HTML
    end

    "<html><body><dl>#{rows.join}</dl></body></html>"
  end

  # Records only need a quote's body and url, so a double keeps the pool and
  # its refill logic out of specs that are not about quoting.
  def stub_next_quote(body: "Sample quote with enough words here.", url: "https://www.quotationspage.com/quote/42.html")
    allow(Quote).to receive(:next!).and_return(double(body: body, url: url))
  end
end

RSpec.configure do |config|
  config.include ExternalServiceStubs
end
