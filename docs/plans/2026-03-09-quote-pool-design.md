# Quote Pool Design

## Goal

Replace the live QuotationsPage scrape on every `Record.create` with a DB-backed quote pool.
Quotes are stored after scraping and drawn from the pool without hitting the network on each request.

## Schema

New `quotes` table:

| column | type | notes |
|---|---|---|
| `body` | text | full quote text |
| `author` | string | quote author name |
| `source_id` | integer | numeric ID from URL (`/quote/2559.html` → `2559`), unique index |
| `url` | string | `https://www.quotationspage.com/quote/NNNN.html` |
| `used_at` | datetime | null = unused; timestamp = when it was drawn |
| `created_at` / `updated_at` | datetime | standard Rails timestamps |

Indexes: unique on `source_id`, index on `used_at`.

## HTML Scraping

QuotationsPage `random.php` returns 20 quotes in a `<dl>`. Each quote is a `<dt class="quote">` /
`<dd class="author">` pair:

```html
<dt class="quote">
  <a href="/quote/2559.html">The first and great commandment is: Don't let them scare you.</a>
</dt>
<dd class="author">
  ...
  <b><a href="/quotes/Elmer_Davis/">Elmer Davis</a> (1890 - 1958)</b>
</dd>
```

Extraction selectors:
- `body` — `dt.quote a` text
- `source_id` — integer parsed from `dt.quote a[href]` (e.g. `/quote/2559.html` → `2559`)
- `url` — `https://www.quotationspage.com/quote/#{source_id}.html`
- `author` — `dd.author b a` text (first link inside the bold tag)

## Quote Model Logic

### `Quote.fetch_more_random_quotes`

1. Scrapes `https://www.quotationspage.com/random.php`
2. Parses all 20 quotes into hashes
3. Calls `insert_all` with `unique_by: :source_id` — only new quotes are inserted
4. Returns the count of newly inserted rows
5. If count == 0 (entire batch already in DB): calls `Quote.update_all(used_at: nil)` to reset the pool

### `Quote.next!`

Single entry point called by `Record#set_album_name`:

```ruby
def self.next!
  fetch_more_random_quotes if where(used_at: nil).count < 20
  where(used_at: nil).order("RANDOM()").limit(20).last.tap do |quote|
    quote.update!(used_at: Time.current)
  end
end
```

### `Record#set_album_name`

Replaces the inline scraping logic:

```ruby
def set_album_name
  quote = Quote.next!
  last_words = quote.body.split(" ").last(4)
  last_words.last.gsub!(/\./, "")
  self.title = last_words.join(" ").titleize
  self.quotationspage_url = quote.url
end
```

## Testing

`Quote` model spec uses WebMock to stub the QuotationsPage HTTP response — no VCR, no network.

Scenarios covered:

- `fetch_more_random_quotes` inserts new quotes from a stubbed HTML response
- `fetch_more_random_quotes` skips duplicates (same `source_id` already in DB)
- `fetch_more_random_quotes` resets `used_at` to nil on all quotes when batch adds no new quotes
- `next!` returns the last of 20 unused quotes and sets `used_at`
- `next!` calls `fetch_more_random_quotes` when fewer than 20 unused quotes exist

`Record` model spec and `root_spec` use VCR. The QuotationsPage cassettes need to be deleted and
re-recorded since the flow now writes to the `quotes` table.

## Files

- Create: `db/migrate/TIMESTAMP_create_quotes.rb`
- Create: `app/models/quote.rb`
- Create: `spec/models/quote_spec.rb`
- Modify: `app/models/record.rb` — replace `set_album_name` body
- Modify: `spec/models/record_spec.rb` — update cassette expectations
- Delete + re-record: `spec/cassettes/root/creates_a_new_album.yml`
- Delete + re-record: `spec/cassettes/Record/` cassettes that include QuotationsPage
