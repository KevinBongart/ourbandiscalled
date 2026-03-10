module Timed
  def self.included(base)
    base.attr_accessor :timings
  end

  private

  def timed(label)
    @timings ||= {}
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @timings[label] = elapsed
    Rails.logger.info("[#{label}] #{(elapsed * 1000).round}ms")
  end
end
