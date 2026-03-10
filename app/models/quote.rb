class Quote < ActiveRecord::Base
  POOL_REFILL_THRESHOLD = 20

  validates :body, presence: true
  validates :source_id, presence: true, uniqueness: true
  validates :url, presence: true

  scope :unused, -> { where(used_at: nil) }

  def self.next!
    unused_count = unused.count

    if unused_count < POOL_REFILL_THRESHOLD
      Rails.logger.info("[Quote] pool miss (#{unused_count} unused) — fetching more")
      FetchQuotes.call
    else
      Rails.logger.info("[Quote] pool hit (#{unused_count} unused)")
    end

    quote = unused.order("RANDOM()").first
    raise "Quote pool is empty and could not fetch more quotes" if quote.nil?

    quote.used!
    quote
  end

  def used!
    update!(used_at: Time.current)
  end
end
