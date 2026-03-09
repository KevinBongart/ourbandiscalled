class Quote < ActiveRecord::Base
  # Fetch more quotes when there are fewer than POOL_REFILL_THRESHOLD
  # unused quotes in the database
  POOL_REFILL_THRESHOLD = 20

  validates :body, presence: true
  validates :source_id, presence: true, uniqueness: true
  validates :url, presence: true

  def self.fetch_more_random_quotes
    rows = scrape_quotes
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

  def self.next!
    unused_count = where(used_at: nil).count
    if unused_count < POOL_REFILL_THRESHOLD
      Rails.logger.info("[Quote] pool miss (#{unused_count} unused) — fetching more")
      fetch_more_random_quotes
    else
      Rails.logger.info("[Quote] pool hit (#{unused_count} unused)")
    end
    quote = where(used_at: nil).order("RANDOM()").first
    raise "Quote pool is empty and could not fetch more quotes" if quote.nil?
    quote.tap { |q| q.update!(used_at: Time.current) }
  end

  private_class_method def self.scrape_quotes
    response = Net::HTTP.get(URI("https://www.quotationspage.com/random.php"))
    doc = Nokogiri::HTML(response)

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
