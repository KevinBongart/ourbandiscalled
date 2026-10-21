require "rails_helper"

RSpec.describe "records" do
  before do
    stub_next_quote
    stub_wikipedia
    stub_flickr
  end

  let(:record) { Record.create! }

  describe "GET /:slug" do
    it "responds successfully" do
      get "/#{record.slug}"

      expect(response).to have_http_status(:ok)
    end

    it "renders the band and album title" do
      get "/#{record.slug}"

      expect(response.body).to include(record.band)
      expect(response.body).to include(record.title)
    end

    it "renders the cover image and the three source links" do
      get "/#{record.slug}"

      expect(response.body).to include(record.cover)
      expect(response.body).to include(record.flickr_url)
      expect(response.body).to include(record.wikipedia_url)
      expect(response.body).to include(record.quotationspage_url)
    end

    it "increments the view counter" do
      expect { get "/#{record.slug}" }.to change { record.reload.views }.from(0).to(1)
    end

    it "counts every visit" do
      3.times { get "/#{record.slug}" }

      expect(record.reload.views).to eq(3)
    end

    it "does not create a new record" do
      record

      expect { get "/#{record.slug}" }.not_to change(Record, :count)
    end

    it "responds 404 for an unknown slug" do
      get "/no-such-album"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /" do
    it "creates a record and redirects to its slug" do
      expect { get "/" }.to change(Record, :count).by(1)

      expect(response).to redirect_to("http://www.example.com/#{Record.last.slug}")
    end

    it "creates a different record on each visit" do
      stub_wikipedia(pages: [ { id: 1, title: "First Band" }, { id: 2, title: "Second Band" } ])

      get "/"
      get "/"

      expect(Record.pluck(:slug).uniq.size).to eq(2)
    end
  end
end
