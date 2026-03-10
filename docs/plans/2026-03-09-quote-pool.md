# Quote Pool Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the live QuotationsPage scrape on every `Record.create` with a DB-backed quote pool, eliminating the ~1.5s QuotationsPage network call from the hot path.

**Architecture:** A new `Quote` model stores scraped quotes with a `used_at` timestamp. `Quote.next!` draws from the unused pool and calls `Quote.fetch_more_random_quotes` to top up when fewer than 20 unused quotes remain. `Record#set_album_name` is replaced with a single `Quote.next!` call.

**Tech Stack:** Rails 8.1, PostgreSQL (`insert_all` with `unique_by`), Nokogiri (already in Gemfile), WebMock (already in test group), RSpec.

---

### Task 1: Migration and `Quote` model skeleton

**Files:**
- Create: `db/migrate/TIMESTAMP_create_quotes.rb`
- Create: `app/models/quote.rb`
- Create: `spec/models/quote_spec.rb`

**Step 1: Write a failing spec**

Create `spec/models/quote_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Quote do
  describe "validations" do
    it "is valid with all required fields" do
      quote = Quote.new(
        body: "To be or not to be.",
        author: "Shakespeare",
        source_id: 42,
        url: "https://www.quotationspage.com/quote/42.html"
      )
      expect(quote).to be_valid
    end

    it "is invalid without body" do
      expect(Quote.new(author: "A", source_id: 1, url: "https://x.com")).not_to be_valid
    end

    it "is invalid without author" do
      expect(Quote.new(body: "A quote", source_id: 1, url: "https://x.com")).not_to be_valid
    end

    it "is invalid without source_id" do
      expect(Quote.new(body: "A quote", author: "A", url: "https://x.com")).not_to be_valid
    end

    it "is invalid with a duplicate source_id" do
      Quote.create!(body: "First", author: "A", source_id: 99, url: "https://www.quotationspage.com/quote/99.html")
      duplicate = Quote.new(body: "Second", author: "B", source_id: 99, url: "https://www.quotationspage.com/quote/99.html")
      expect(duplicate).not_to be_valid
    end
  end
end
```

**Step 2: Run the spec to confirm it fails**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec spec/models/quote_spec.rb -f documentation
```

Expected: FAIL — `Quote` constant uninitialized.

**Step 3: Generate the migration**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rails generate migration CreateQuotes body:text author:string source_id:integer url:string used_at:datetime
```

Open the generated migration and edit it to add null constraints and indexes:

```ruby
class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.text :body, null: false
      t.string :author, null: false
      t.integer :source_id, null: false
      t.string :url, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :quotes, :source_id, unique: true
    add_index :quotes, :used_at
  end
end
```

**Step 4: Run the migration**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rails db:migrate && bundle exec rails db:migrate RAILS_ENV=test
```

**Step 5: Create `app/models/quote.rb`**

```ruby
class Quote < ApplicationRecord
  validates :body, presence: true
  validates :author, presence: true
  validates :source_id, presence: true, uniqueness: true
  validates :url, presence: true
end
```

**Step 6: Run the spec to confirm it passes**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec spec/models/quote_spec.rb -f documentation
```

Expected: all 5 examples pass.

**Step 7: Run the full suite**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec -f documentation
```

Expected: all passing.

**Step 8: Commit**

```bash
cd /Users/kevin/Code/ourbandiscalled && git add db/migrate/ db/schema.rb app/models/quote.rb spec/models/quote_spec.rb && git commit -m "feat: add Quote model and migration"
```

---

### Task 2: Implement `Quote.fetch_more_random_quotes`

**Files:**
- Modify: `app/models/quote.rb`
- Modify: `spec/models/quote_spec.rb`

The HTML structure of `https://www.quotationspage.com/random.php`:

```html
<dt class="quote"><a href="/quote/2559.html">Quote text here.</a></dt>
<dd class="author"><b><a href="/quotes/Author_Name/">Author Name</a> (1890 - 1958)</b></dd>
```

Each `dt.quote` is followed immediately by a `dd.author`. Extract:
- `body` — `dt.quote a` text (stripped)
- `source_id` — integer from href: `/quote/2559.html` → `2559`
- `url` — `https://www.quotationspage.com/quote/#{source_id}.html`
- `author` — `dd.author b a` first link text (stripped)

**Step 1: Add the HTML fixture constant and failing specs**

Add to `spec/models/quote_spec.rb` after the `validations` describe block:

```ruby
QUOTATIONS_PAGE_HTML = <<~HTML.freeze
  <html><body><dl>
    <dt class="quote"><a href="/quote/100.html">First quote text.</a></dt>
    <dd class="author"><div class="icons"></div><b><a href="/quotes/Author_One/">Author One</a></b></dd>
    <dt class="quote"><a href="/quote/200.html">Second quote text here.</a></dt>
    <dd class="author"><div class="icons"></div><b><a href="/quotes/Author_Two/">Author Two</a> (1900 - 1980)</b></dd>
    <dt class="quote"><a href="/quote/300.html">Third and final text.</a></dt>
    <dd class="author"><div class="icons"></div><b><a href="/quotes/Author_Three/">Author Three</a></b></dd>
  </dl></body></html>
HTML

describe ".fetch_more_random_quotes" do
  before do
    stub_request(:get, "https://www.quotationspage.com/random.php")
      .to_return(body: QUOTATIONS_PAGE_HTML, status: 200)
  end

  it "inserts quotes parsed from the page" do
    expect { Quote.fetch_more_random_quotes }.to change(Quote, :count).by(3)

    quote = Quote.find_by(source_id: 100)
    expect(quote.body).to eq("First quote text.")
    expect(quote.author).to eq("Author One")
    expect(quote.url).to eq("https://www.quotationspage.com/quote/100.html")
    expect(quote.used_at).to be_nil
  end

  it "skips quotes already in the database (deduplicates by source_id)" do
    Quote.create!(body: "Old text", author: "Author One", source_id: 100, url: "https://www.quotationspage.com/quote/100.html")
    expect { Quote.fetch_more_random_quotes }.to change(Quote, :count).by(2)
  end

  it "resets used_at to nil on all quotes when no new quotes are added" do
    Quote.create!(body: "First quote text.", author: "Author One", source_id: 100, url: "https://www.quotationspage.com/quote/100.html", used_at: 1.hour.ago)
    Quote.create!(body: "Second quote text here.", author: "Author Two", source_id: 200, url: "https://www.quotationspage.com/quote/200.html", used_at: 2.hours.ago)
    Quote.create!(body: "Third and final text.", author: "Author Three", source_id: 300, url: "https://www.quotationspage.com/quote/300.html", used_at: 3.hours.ago)

    expect { Quote.fetch_more_random_quotes }.not_to change(Quote, :count)
    expect(Quote.where(used_at: nil).count).to eq(3)
  end
end
```

**Step 2: Run the new specs to confirm they fail**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec spec/models/quote_spec.rb -e "fetch_more_random_quotes" -f documentation
```

Expected: FAIL — method undefined.

**Step 3: Implement `fetch_more_random_quotes` in `app/models/quote.rb`**

Add inside the class, before the closing `end`:

```ruby
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
```

**Step 4: Run the specs to confirm they pass**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec spec/models/quote_spec.rb -f documentation
```

Expected: all passing.

**Step 5: Run the full suite**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec -f documentation
```

Expected: all passing.

**Step 6: Commit**

```bash
cd /Users/kevin/Code/ourbandiscalled && git add app/models/quote.rb spec/models/quote_spec.rb && git commit -m "feat: implement Quote.fetch_more_random_quotes"
```

---

### Task 3: Implement `Quote.next!`

**Files:**
- Modify: `app/models/quote.rb`
- Modify: `spec/models/quote_spec.rb`

**Step 1: Add failing specs for `Quote.next!`**

Add to `spec/models/quote_spec.rb`:

```ruby
describe ".next!" do
  def create_quotes(count, used: false)
    count.times do |i|
      Quote.create!(
        body: "Quote number #{i}",
        author: "Author #{i}",
        source_id: i + 1,
        url: "https://www.quotationspage.com/quote/#{i + 1}.html",
        used_at: used ? i.hours.ago : nil
      )
    end
  end

  context "with 20 or more unused quotes in the database" do
    before { create_quotes(25) }

    it "returns a Quote instance" do
      expect(Quote.next!).to be_a(Quote)
    end

    it "marks the returned quote as used" do
      quote = Quote.next!
      expect(quote.reload.used_at).to be_present
    end

    it "does not call fetch_more_random_quotes" do
      expect(Quote).not_to receive(:fetch_more_random_quotes)
      Quote.next!
    end
  end

  context "with fewer than 20 unused quotes" do
    before do
      create_quotes(5)
      stub_request(:get, "https://www.quotationspage.com/random.php")
        .to_return(body: QUOTATIONS_PAGE_HTML, status: 200)
    end

    it "calls fetch_more_random_quotes" do
      expect(Quote).to receive(:fetch_more_random_quotes).and_call_original
      Quote.next!
    end

    it "returns a quote after fetching more" do
      expect(Quote.next!).to be_a(Quote)
    end
  end
end
```

**Step 2: Run the new specs to confirm they fail**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec spec/models/quote_spec.rb -e "next!" -f documentation
```

Expected: FAIL — method undefined.

**Step 3: Implement `Quote.next!` in `app/models/quote.rb`**

Add after `fetch_more_random_quotes`:

```ruby
def self.next!
  fetch_more_random_quotes if where(used_at: nil).count < 20
  where(used_at: nil).order("RANDOM()").limit(20).last.tap do |quote|
    quote.update!(used_at: Time.current)
  end
end
```

**Step 4: Run the specs to confirm they pass**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec spec/models/quote_spec.rb -f documentation
```

Expected: all passing.

**Step 5: Run the full suite**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec -f documentation
```

Expected: all passing.

**Step 6: Commit**

```bash
cd /Users/kevin/Code/ourbandiscalled && git add app/models/quote.rb spec/models/quote_spec.rb && git commit -m "feat: implement Quote.next!"
```

---

### Task 4: Wire up `Record#set_album_name` and update cassettes

**Files:**
- Modify: `app/models/record.rb`
- Modify: `spec/models/record_spec.rb`
- Modify: `spec/requests/root_spec.rb`
- Delete: `spec/cassettes/Record/` (all — re-recorded below)
- Delete: `spec/cassettes/root/creates_a_new_album.yml`
- Delete: `spec/cassettes/root/redirects_to_the_album_page.yml`

**Step 1: Update `Record#set_album_name` in `app/models/record.rb`**

Replace the entire `set_album_name` method:

```ruby
def set_album_name
  quote = Quote.next!
  last_words = quote.body.split(" ").last(4)
  last_words.last.gsub!(/\./, "")
  self.title = last_words.join(" ").titleize
  self.quotationspage_url = quote.url
end
```

**Step 2: Update `spec/models/record_spec.rb` to pre-seed quotes**

The record spec must not trigger `fetch_more_random_quotes` (no network call needed). Pre-seed 20 quotes before each test.

Replace the full file:

```ruby
require "rails_helper"

RSpec.describe Record do
  def seed_quotes(count = 20)
    count.times do |i|
      Quote.create!(
        body: "Sample quote number #{i} with enough words here.",
        author: "Author #{i}",
        source_id: i + 1,
        url: "https://www.quotationspage.com/quote/#{i + 1}.html"
      )
    end
  end

  describe "#generate_content" do
    before { seed_quotes }

    it "populates all fields on create", :vcr do
      record = Record.create

      expect(record.band).to be_present
      expect(record.wikipedia_url).to be_present
      expect(record.title).to be_present
      expect(record.quotationspage_url).to be_present
      expect(record.cover).to be_present
      expect(record.flickr_url).to be_present
      expect(record.slug).to be_present
    end

    it "only fetches Flickr once when creating two records", :vcr do
      allow(Net::HTTP).to receive(:get).and_call_original
      expect(Net::HTTP).to receive(:get).with(URI("https://www.flickr.com/explore")).once.and_call_original
      Record.create
      Record.create
    end
  end
end
```

**Step 3: Delete stale VCR cassettes**

```bash
rm -rf /Users/kevin/Code/ourbandiscalled/spec/cassettes/Record
rm /Users/kevin/Code/ourbandiscalled/spec/cassettes/root/creates_a_new_album.yml
rm /Users/kevin/Code/ourbandiscalled/spec/cassettes/root/redirects_to_the_album_page.yml
```

**Step 4: Update `spec/requests/root_spec.rb`**

The root spec must also pre-seed quotes. Update to relax the quote-specific assertions (title, quotationspage_url, slug are now non-deterministic due to `ORDER BY RANDOM()`), and update the redirect assertion accordingly.

Replace the full file:

```ruby
require "rails_helper"

RSpec.describe "root", :vcr do
  subject { get("/") }

  before do
    20.times do |i|
      Quote.create!(
        body: "Sample quote number #{i} with enough words here.",
        author: "Author #{i}",
        source_id: i + 1,
        url: "https://www.quotationspage.com/quote/#{i + 1}.html"
      )
    end
  end

  it "creates a new album" do
    expect(Record.count).to eq(0)

    subject

    expect(Record.count).to eq(1)
    record = Record.first

    expect(record.band).to eq("General Stanton")
    expect(record.wikipedia_url).to eq("http://en.wikipedia.org/wiki/General_Stanton")

    expect(record.title).to be_present
    expect(record.quotationspage_url).to match(%r{https://www\.quotationspage\.com/quote/\d+\.html})

    expect(record.cover).to be_in %w[
      https://live.staticflickr.com/65535/52878248290_e0a6fe735d.jpg
      https://live.staticflickr.com/65535/52876917062_0047267662_n.jpg
      https://live.staticflickr.com/65535/52880477935_96c49d3a2c_w.jpg
      https://live.staticflickr.com/65535/52880262073_8c855ca5ff_w.jpg
      https://live.staticflickr.com/65535/52881373403_4a5ae55326_w.jpg
      https://live.staticflickr.com/65535/52879838189_596bff8b5c_w.jpg
      https://live.staticflickr.com/65535/52878407955_f3f6e91e1b_w.jpg
      https://live.staticflickr.com/65535/52878414141_bb55cd9a81_w.jpg
      https://live.staticflickr.com/65535/52880551393_8cdde6af5e_w.jpg
      https://live.staticflickr.com/65535/52879199102_23f6840cb5_n.jpg
      https://live.staticflickr.com/65535/52880090174_c2621fee8c_w.jpg
      https://live.staticflickr.com/65535/52878368235_207c1ab403.jpg
      https://live.staticflickr.com/65535/52877720123_2250ec3b4c_w.jpg
      https://live.staticflickr.com/65535/52881545943_e78aa1eb6a_w.jpg
      https://live.staticflickr.com/65535/52879903035_dbdda03e90_w.jpg
      https://live.staticflickr.com/65535/52877158616_d7b2fda49d_w.jpg
      https://live.staticflickr.com/65535/52878305485_289028965a_w.jpg
      https://live.staticflickr.com/65535/52877939602_ffede50c30_w.jpg
      https://live.staticflickr.com/65535/52880122010_a06163d98a_z.jpg
      https://live.staticflickr.com/65535/52876403157_11b300032b.jpg
      https://live.staticflickr.com/65535/52879955584_1dc230415f_w.jpg
      https://live.staticflickr.com/65535/52878484073_15fcbe0fa2_w.jpg
      https://live.staticflickr.com/65535/52880539440_13d4cf5cb0_w.jpg
      https://live.staticflickr.com/65535/52880205240_1b9eb8069d_n.jpg
      https://live.staticflickr.com/65535/52875726504_83ca286fd4_w.jpg
      https://live.staticflickr.com/65535/52878596679_dfe850f2c6_w.jpg
      https://live.staticflickr.com/65535/52876218128_83992582a5.jpg
      https://live.staticflickr.com/65535/52877887264_83f251af8c_z.jpg
      https://live.staticflickr.com/65535/52880249968_136f7d94fc_w.jpg
      https://live.staticflickr.com/65535/52877213512_04d713cd15_n.jpg
      https://live.staticflickr.com/65535/52877864293_bdc3b2471e_w.jpg
      https://live.staticflickr.com/65535/52879525282_694910c655_n.jpg
      https://live.staticflickr.com/65535/52878106096_0d9879a221_w.jpg
      https://live.staticflickr.com/65535/52880712830_9e4602fa1c_w.jpg
      https://live.staticflickr.com/65535/52877550223_92e9e9c405_n.jpg
      https://live.staticflickr.com/65535/52878413387_e042eab191.jpg
      https://live.staticflickr.com/65535/52876645611_7b782e37f2.jpg
      https://live.staticflickr.com/65535/52881012384_6dd173aff6_n.jpg
      https://live.staticflickr.com/65535/52879158957_9564a3a830_n.jpg
      https://live.staticflickr.com/65535/52877501116_e7bfa4ef8f.jpg
      https://live.staticflickr.com/65535/52879647011_c6e226bbaf_w.jpg
      https://live.staticflickr.com/65535/52876638589_70ef97f331_n.jpg
      https://live.staticflickr.com/65535/52879210527_37092fe49f_w.jpg
      https://live.staticflickr.com/65535/52879924233_347b56d95a.jpg
      https://live.staticflickr.com/65535/52876600446_55cfcba741_n.jpg
      https://live.staticflickr.com/65535/52879006067_f7eb12bd48_w.jpg
      https://live.staticflickr.com/65535/52876154683_1273a6bfc4_w.jpg
      https://live.staticflickr.com/65535/52878034280_366b45ca51_w.jpg
      https://live.staticflickr.com/65535/52879166617_9175ab0055_w.jpg
    ]

    expect(record.flickr_url).to match(/http:\/\/flickr\.com\/photo\.gne\?id=\d+/)
    expect(record.slug).to be_present
    expect(record.views).to eq(0)
  end

  it "redirects to the album page" do
    subject

    expect(response).to redirect_to(%r{http://www\.example\.com/.+-by-.+})
    follow_redirect!

    expect(response.body).to be_present
  end
end
```

**Step 5: Record new VCR cassettes by running the specs against real APIs**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec spec/requests/root_spec.rb spec/models/record_spec.rb -f documentation
```

Expected: PASS with new cassettes recorded at:
- `spec/cassettes/root/creates_a_new_album.yml`
- `spec/cassettes/root/redirects_to_the_album_page.yml`
- `spec/cassettes/Record/_generate_content/populates_all_fields_on_create.yml`
- `spec/cassettes/Record/_generate_content/only_fetches_Flickr_once_when_creating_two_records.yml`

Note: these cassettes will only contain Wikipedia and Flickr HTTP interactions — no QuotationsPage, since quotes are pre-seeded.

**Step 6: Run the full suite**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rspec -f documentation
```

Expected: all passing.

**Step 7: Run RuboCop**

```bash
cd /Users/kevin/Code/ourbandiscalled && bundle exec rubocop
```

Fix any offenses with `--autocorrect` if needed.

**Step 8: Commit**

```bash
cd /Users/kevin/Code/ourbandiscalled && git add app/models/record.rb spec/models/record_spec.rb spec/requests/root_spec.rb spec/cassettes/ && git commit -m "feat: wire Record#set_album_name to Quote.next!"
```
