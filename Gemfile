source "https://rubygems.org"
ruby File.read(".ruby-version").chomp

gem "rails", "~>8.1"

gem "newrelic_rpm"
gem "nokogiri"
gem "pg"
gem "propshaft"
gem "puma"

group :development, :test do
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails"
  gem "rspec_junit_formatter"
end

group :development do
  gem "listen"
  gem "rubocop-rails-omakase", require: false
  gem "web-console"
end

group :test do
  gem "vcr"
  gem "webmock"
end
