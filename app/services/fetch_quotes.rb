class FetchQuotes
  include HttpFetchable

  def self.call
    new.call
  end

  def call
    rows = scrape
    count_before = Quote.count
    now = Time.current
    Quote.insert_all(
      rows.map { |r| r.merge(created_at: now, updated_at: now) },
      unique_by: :source_id
    )
    newly_added = Quote.count - count_before
    Quote.update_all(used_at: nil) if newly_added == 0
    newly_added
  end

  private

  def scrape
    doc = Nokogiri::HTML(http_get("https://www.quotationspage.com/random.php"))

    doc.css("dt.quote").map do |dt|
      link = dt.css("a").first
      href = link["href"]
      source_id = href.match(/\/quote\/(\d+)\.html/)[1].to_i
      author = dt.next_element.css("b a").first&.text&.strip || ""

      {
        body: link.text.strip,
        author: author,
        source_id: source_id,
        url: "https://www.quotationspage.com/quote/#{source_id}.html"
      }
    end
  end
end
