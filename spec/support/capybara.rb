require "capybara/rails"
require "capybara/rspec"

# The app ships no JavaScript, so the rack_test driver exercises everything a
# real browser would and keeps the suite fast and dependency-free.
Capybara.default_driver = :rack_test
