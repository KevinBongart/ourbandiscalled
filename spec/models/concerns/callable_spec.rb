require "rails_helper"

RSpec.describe Callable do
  let(:service) do
    Class.new do
      include Callable

      def call(suffix = "")
        "called#{suffix}"
      end
    end
  end

  describe ".call" do
    it "forwards to a new instance" do
      expect(service.call).to eq("called")
    end

    it "passes arguments through" do
      expect(service.call("!")).to eq("called!")
    end
  end
end
