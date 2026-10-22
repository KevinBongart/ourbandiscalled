require "rails_helper"

RSpec.describe Timed do
  let(:subject_class) do
    Class.new do
      include Timed

      def run(label)
        timed(label) { yield_target }
      end

      def yield_target
        :done
      end
    end
  end

  let(:instance) { subject_class.new }

  describe "#timed" do
    it "runs the block" do
      expect(instance).to receive(:yield_target)

      instance.run("Work")
    end

    it "records an elapsed time under the given label" do
      instance.run("Work")

      expect(instance.timings).to have_key("Work")
      expect(instance.timings["Work"]).to be_a(Float)
    end

    it "accumulates timings across labels" do
      instance.run("First")
      instance.run("Second")

      expect(instance.timings.keys).to contain_exactly("First", "Second")
    end

    it "logs the elapsed time in milliseconds" do
      allow(Rails.logger).to receive(:info)

      instance.run("Work")

      expect(Rails.logger).to have_received(:info).with(/\A\[Work\] \d+ms\z/)
    end
  end
end
