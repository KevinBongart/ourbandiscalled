# API Fetch Benchmarking & Feature Flags Design

## Goal

Establish a local benchmark baseline for `Record.create`, then add two ENV-driven optimizations
(parallel API fetches, Flickr photo caching) that can be toggled independently and compared
side-by-side against the baseline.

## Model Refactor

Consolidate the four `before_create` callbacks in `Record` into a single `generate_content` method.
This is more idiomatic Rails and makes the dispatch logic for feature variants easy to follow.

```ruby
before_create :generate_content

def generate_content
  set_band_name
  set_album_name
  set_album_cover
  set_slug
end
```

## Feature Flags

Two env vars control optimization strategies at runtime (read inside method bodies, not at class load):

| Env var | Default | Effect |
|---|---|---|
| `PARALLEL_FETCH=true` | off | Runs `set_band_name`, `set_album_name`, `set_album_cover` in parallel threads |
| `CACHE_FLICKR=true` | off | Wraps the Flickr HTTP fetch in `Rails.cache.fetch` with a 5-minute TTL |

### PARALLEL_FETCH

`generate_content` branches on this flag:

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

`set_slug` always runs last since it depends on `band` and `title`.

### CACHE_FLICKR

Inside `set_album_cover`, the Flickr HTTP fetch is wrapped:

```ruby
photo_urls = Rails.cache.fetch("flickr_photos", expires_in: 5.minutes) do
  # existing Net::HTTP fetch and Nokogiri parse
end
```

The rest of the method is unchanged. The cache warms on the first call; subsequent calls within
the TTL skip the HTTP request entirely.

## Benchmark Rake Task

File: `lib/tasks/benchmark.rake`
Task: `rake benchmark`

Runs all 4 variants in sequence, 10 real `Record.create` calls each, against live external APIs.
Created records are deleted after each variant. A comparison table is printed at the end.

### Variants

| Label | PARALLEL_FETCH | CACHE_FLICKR |
|---|---|---|
| baseline | false | false |
| parallel_fetch | true | false |
| flickr_cache | false | true |
| parallel + flickr_cache | true | true |

### Stats per variant

Mean, min, max, and stddev of wall-clock seconds per `Record.create` call, measured with
`Process.clock_gettime(Process::CLOCK_MONOTONIC)`.

### Cache setup

`Rails.cache` uses the default file store in development. The rake task enables caching before
running cache variants so results are valid locally without extra configuration.

### Run order

Baseline runs first (no cache warm-up bias). Cache variants run after, so the first run of each
cache variant pays the warm-up cost — this is intentional and reflects real-world behavior.

## Files Changed

- `app/models/record.rb` — refactor + feature flag branches
- `lib/tasks/benchmark.rake` — new file
