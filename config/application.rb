require_relative "boot"

# require "rails"

# Pick the frameworks you want:
require "action_controller/railtie"
require "action_view/railtie"
require "active_model/railtie"
require "active_record/railtie"
# Propshaft is loaded via Bundler.require below

# Action Cable, Action Mailer, Active Job, Active Storage and the test_unit
# railtie are intentionally not loaded. Their gems are no longer installed
# either -- the Gemfile lists the individual frameworks instead of the "rails"
# meta-gem -- so re-enabling one means adding its gem back first.

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ourbandiscalled
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
