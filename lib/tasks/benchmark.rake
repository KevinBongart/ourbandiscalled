desc "Benchmark Record.create with per-method timing (10 runs, hits real APIs)"
task benchmark: :environment do
  runs = 10
  times = []

  ActionController::Base.perform_caching = true
  Rails.cache = ActiveSupport::Cache::MemoryStore.new
  Rails.cache.clear

  puts "Running #{runs} benchmarks...\n\n"

  runs.times do |i|
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    record = Record.create!
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    times << elapsed
    breakdown = record.timings.map { |k, v| "#{k}=#{v.round(3)}s" }.join("  ")
    record.destroy
    print "  run #{i + 1}/#{runs}: #{elapsed.round(3)}s  [#{breakdown}]\n"
  end

  mean   = times.sum / times.size
  min    = times.min
  max    = times.max
  stddev = Math.sqrt(times.map { |t| (t - mean) ** 2 }.sum / times.size)

  puts "\n#{'=' * 50}"
  puts format("  mean: %.3fs  min: %.3fs  max: %.3fs  stddev: %.3fs", mean, min, max, stddev)
  puts "=" * 50
end
