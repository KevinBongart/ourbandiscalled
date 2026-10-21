require "capybara/rails"
require "capybara/rspec"
require "selenium-webdriver"

# Most of the app ships no JavaScript, so rack_test exercises everything a real
# browser would and keeps the suite fast.
Capybara.default_driver = :rack_test

# Accessibility specs are the exception: axe-core runs inside the page, so they
# need a real browser. Tag an example with `js: true` to get one.
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome

RSpec.configure do |config|
  # webmock/rspec blocks all net connections, including the ones Capybara's own
  # server and chromedriver need. Outbound stubs still apply, so the app's
  # external calls stay mocked.
  config.around(:each, js: true) do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.disable_net_connect!(allow_localhost: false)
  end
end
