source "https://rubygems.org"
ruby File.read(".ruby-version").chomp

# Only the Rails frameworks this app actually loads (see config/application.rb).
# Action Cable, Action Mailer, Action Mailbox, Action Text, Active Job and
# Active Storage are deliberately omitted.
gem "actionpack", "~> 8.1"
gem "actionview", "~> 8.1"
gem "activemodel", "~> 8.1"
gem "activerecord", "~> 8.1"
gem "railties", "~> 8.1"

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
