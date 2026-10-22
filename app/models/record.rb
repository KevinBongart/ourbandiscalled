class Record < ActiveRecord::Base
  include Timed

  before_create :generate_content

  def to_param
    slug
  end

  private

  def generate_content
    threads = [
      Thread.new { timed("Wikipedia") { set_band_name } },
      Thread.new { timed("Quote") { set_album_name } },
      Thread.new { timed("Flickr") { set_album_cover } }
    ]
    threads.each(&:join)

    set_slug
  end

  def set_band_name
    page = RandomWikipediaPage.call

    self.band = page.band_name
    self.wikipedia_url = page.url
  end

  def set_album_name
    quotation = RandomQuote.call

    self.title = quotation.album_title
    self.quotationspage_url = quotation.url
  end

  def set_album_cover
    photo = RandomFlickrPhoto.call

    self.cover = photo.image_url
    self.flickr_url = photo.page_url
  end

  def set_slug
    self.slug = "#{title.parameterize}-by-#{band.parameterize}"
  end
end
