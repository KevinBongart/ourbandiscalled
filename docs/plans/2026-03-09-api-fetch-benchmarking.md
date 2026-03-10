# API Fetch Benchmarking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor `Record` to idiomatic Rails, add `PARALLEL_FETCH` and `CACHE_FLICKR` feature flags, and create a rake task that benchmarks all four combinations with 10 runs each.

**Architecture:** A single `before_create :generate_content` callback dispatches to three private fetch methods either sequentially or in parallel threads based on `ENV['PARALLEL_FETCH']`. The Flickr fetch is wrapped in `Rails.cache.fetch` when `ENV['CACHE_FLICKR']` is set. A rake task sets these env vars and times `Record.create` across all four variants.

**Tech Stack:** Ruby/Rails 8.1, RSpec + VCR + WebMock (existing test setup), `Process.clock_gettime` for timing, `Rails.cache` memory store for local caching.

---

### Task 1: Refactor `record.rb` — consolidate callbacks into `generate_content`

**Files:**
- Modify: `app/models/record.rb`
- Create: `spec/models/record_spec.rb`

**Step 1: Write the failing model spec**

Create `spec/models/record_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Record, :vcr do
  describe '#generate_content' do
    it 'populates all fields on create' do
      record = Record.create

      expect(record.band).to be_present
      expect(record.wikipedia_url).to be_present
      expect(record.title).to be_present
      expect(record.quotationspage_url).to be_present
      expect(record.cover).to be_present
      expect(record.flickr_url).to be_present
      expect(record.slug).to be_present
    end
  end
end
```

**Step 2: Run the spec to confirm it fails**

```bash
bundle exec rspec spec/models/record_spec.rb -f documentation
```

Expected: FAIL — no cassette recorded yet (VCR will raise).

**Step 3: Record the VCR cassette**

VCR will auto-create the cassette on the first run against real APIs. Run once with VCR in record mode by temporarily adding `record: :new_episodes` to the `:vcr` tag, or simply delete/missing cassette triggers auto-record.

Run with real network access:

```bash
bundle exec rspec spec/models/record_spec.rb -f documentation
```

Expected: PASS (cassette created at `spec/cassettes/Record/generate_content/populates_all_fields_on_create.yml`).

**Step 4: Refactor `app/models/record.rb`**

Replace:

```ruby
before_create :set_band_name
before_create :set_album_name
before_create :set_album_cover
before_create :set_slug
```

With:

```ruby
before_create :generate_content
```

Add after the `to_param` method, inside `private`:

```ruby
def generate_content
  set_band_name
  set_album_name
  set_album_cover
  set_slug
end
```

Remove the `require 'open-uri'` line if it is unused (the methods use `Net::HTTP`, not `open-uri`).

**Step 5: Run all specs to confirm nothing broke**

```bash
bundle exec rspec -f documentation
```

Expected: all passing (same VCR cassettes replay correctly).

**Step 6: Commit**

```bash
git add app/models/record.rb spec/models/record_spec.rb spec/cassettes/
git commit -m "refactor: consolidate before_create callbacks into generate_content"
```

---

### Task 2: Add `PARALLEL_FETCH` feature flag

**Files:**
- Modify: `app/models/record.rb`
- Modify: `spec/models/record_spec.rb`

**Step 1: Write the failing spec for parallel behavior**

Add to `spec/models/record_spec.rb`:

```ruby
describe 'PARALLEL_FETCH feature flag' do
  around do |example|
    original = ENV['PARALLEL_FETCH']
    ENV['PARALLEL_FETCH'] = 'true'
    example.run
    ENV['PARALLEL_FETCH'] = original
  end

  it 'populates all fields when parallel fetch is enabled', :vcr do
    record = Record.create

    expect(record.band).to be_present
    expect(record.wikipedia_url).to be_present
    expect(record.title).to be_present
    expect(record.quotationspage_url).to be_present
    expect(record.cover).to be_present
    expect(record.flickr_url).to be_present
    expect(record.slug).to be_present
  end
end
```

**Step 2: Run the spec to confirm it fails**

```bash
bundle exec rspec spec/models/record_spec.rb -f documentation
```

Expected: FAIL — VCR cassette missing.

**Step 3: Record the cassette**

Run once against real APIs (VCR auto-records). Note: WebMock is thread-safe and VCR cassettes work with threads since Net::HTTP is intercepted at the socket level.

```bash
bundle exec rspec spec/models/record_spec.rb:'PARALLEL_FETCH feature flag' -f documentation
```

Expected: PASS (cassette created).

**Step 4: Add the parallel branch to `generate_content` in `app/models/record.rb`**

Replace:

```ruby
def generate_content
  set_band_name
  set_album_name
  set_album_cover
  set_slug
end
```

With:

```ruby
def generate_content
  if ENV['PARALLEL_FETCH'] == 'true'
    threads = [
      Thread.new { set_band_name },
      Thread.new { set_album_name },
      Thread.new { set_album_cover }
    ]
    threads.each(&:join)
  else
    set_band_name
    set_album_name
    set_album_cover
  end
  set_slug
end
```

**Step 5: Run all specs**

```bash
bundle exec rspec -f documentation
```

Expected: all passing.

**Step 6: Commit**

```bash
git add app/models/record.rb spec/models/record_spec.rb spec/cassettes/
git commit -m "feat: add PARALLEL_FETCH feature flag to generate_content"
```

---

### Task 3: Add `CACHE_FLICKR` feature flag

**Files:**
- Modify: `app/models/record.rb`
- Modify: `spec/models/record_spec.rb`
- Modify: `config/environments/development.rb` (enable caching)

**Step 1: Write the failing spec for cache behavior**

Add to `spec/models/record_spec.rb`:

```ruby
describe 'CACHE_FLICKR feature flag' do
  around do |example|
    original = ENV['CACHE_FLICKR']
    ENV['CACHE_FLICKR'] = 'true'
    Rails.cache.clear
    example.run
    Rails.cache.clear
    ENV['CACHE_FLICKR'] = original
  end

  it 'populates cover on create', :vcr do
    record = Record.create
    expect(record.cover).to be_present
    expect(record.flickr_url).to be_present
  end

  it 'only fetches Flickr once when creating two records', :vcr do
    expect(Net::HTTP).to receive(:get).with(URI('https://www.flickr.com/explore')).once.and_call_original
    Record.create
    Record.create
  end
end
```

**Step 2: Run the spec to confirm it fails**

```bash
bundle exec rspec spec/models/record_spec.rb -f documentation
```

Expected: FAIL.

**Step 3: Add the cache branch to `set_album_cover` in `app/models/record.rb`**

Replace the body of `set_album_cover`:

```ruby
def set_album_cover
  photo_urls = if ENV['CACHE_FLICKR'] == 'true'
    Rails.cache.fetch('flickr_photos', expires_in: 5.minutes) do
      response = Net::HTTP.get URI('https://www.flickr.com/explore')
      body = Nokogiri::HTML response
      body.search('.photo-list-photo-container img').map { |img| img['src'] }
    end
  else
    response = Net::HTTP.get URI('https://www.flickr.com/explore')
    body = Nokogiri::HTML response
    body.search('.photo-list-photo-container img').map { |img| img['src'] }
  end

  album_cover = "https:#{photo_urls.sample}"

  self.cover = album_cover
  self.flickr_url = "http://flickr.com/photo.gne?id=#{album_cover.split('/')[4].split('_')[0]}"
end
```

**Step 4: Ensure `Rails.cache` works in the test environment**

In `spec/rails_helper.rb`, add inside `RSpec.configure`:

```ruby
config.before(:each) do
  Rails.cache.clear
end
```

The test env uses `:null_store` by default, which won't actually cache. Add to `config/environments/test.rb` (or check if it exists; Rails 8 generates it):

```ruby
config.cache_store = :memory_store
```

**Step 5: Run all specs**

```bash
bundle exec rspec -f documentation
```

Expected: all passing.

**Step 6: Commit**

```bash
git add app/models/record.rb spec/models/record_spec.rb spec/rails_helper.rb config/environments/test.rb spec/cassettes/
git commit -m "feat: add CACHE_FLICKR feature flag to set_album_cover"
```

---

### Task 4: Create the benchmark rake task

**Files:**
- Create: `lib/tasks/benchmark.rake`

There are no unit tests for a benchmark task. Verify by running it.

**Step 1: Create `lib/tasks/benchmark.rake`**

```ruby
namespace :benchmark do
  desc 'Benchmark all API fetch strategy combinations (10 runs each, hits real APIs)'
  task run: :environment do
    require 'benchmark'

    variants = [
      { label: 'baseline',               parallel: false, cache: false },
      { label: 'parallel_fetch',         parallel: true,  cache: false },
      { label: 'flickr_cache',           parallel: false, cache: true  },
      { label: 'parallel + flickr_cache', parallel: true, cache: true  },
    ]

    runs = 10
    results = []

    variants.each do |variant|
      ENV['PARALLEL_FETCH'] = variant[:parallel] ? 'true' : nil
      ENV['CACHE_FLICKR']   = variant[:cache]    ? 'true' : nil

      if variant[:cache]
        ActionController::Base.perform_caching = true
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        Rails.cache.clear
      end

      puts "\nRunning variant: #{variant[:label]} (#{runs} runs)..."
      times = []

      runs.times do |i|
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        record = Record.create!
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        times << elapsed
        record.destroy
        print "  run #{i + 1}/#{runs}: #{elapsed.round(3)}s\n"
      end

      mean   = times.sum / times.size
      min    = times.min
      max    = times.max
      stddev = Math.sqrt(times.map { |t| (t - mean) ** 2 }.sum / times.size)

      results << {
        label:  variant[:label],
        mean:   mean,
        min:    min,
        max:    max,
        stddev: stddev,
      }
    end

    puts "\n\n#{'=' * 70}"
    puts "RESULTS"
    puts '=' * 70
    puts format("%-30s %6s %6s %6s %6s", 'Variant', 'Mean', 'Min', 'Max', 'Stddev')
    puts '-' * 70
    results.each do |r|
      puts format("%-30s %5.2fs %5.2fs %5.2fs %5.2fs",
        r[:label], r[:mean], r[:min], r[:max], r[:stddev])
    end
    puts '=' * 70
  end
end

desc 'Alias for benchmark:run'
task benchmark: 'benchmark:run'
```

**Step 2: Run the benchmark**

```bash
bundle exec rake benchmark
```

Expected: runs all 4 variants, prints timing per run, then a comparison table. Takes ~5-15 minutes depending on network conditions.

**Step 3: Commit**

```bash
git add lib/tasks/benchmark.rake
git commit -m "feat: add benchmark rake task for API fetch strategy comparison"
```
