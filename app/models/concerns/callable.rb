# Gives a service the conventional `Service.call` entry point, forwarding to a
# fresh instance so each invocation starts from clean state.
module Callable
  extend ActiveSupport::Concern

  class_methods do
    def call(...)
      new.call(...)
    end
  end
end
