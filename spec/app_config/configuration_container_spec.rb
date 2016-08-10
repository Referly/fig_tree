require "spec_helper"

describe AppConfig::ConfigurationContainer do
  describe "registering a new parameter" do
    it "registers a setter" do
      subject.parameter :foo

      expect { subject.foo = "foo" }.not_to raise_error
    end
  end
end
