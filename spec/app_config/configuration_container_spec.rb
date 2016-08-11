require "spec_helper"

describe FigTree::ConfigurationContainer do
  describe "registering a new parameter" do
    it "registers a setter" do
      subject.parameter :foo

      expect { subject.foo = "foo" }.not_to raise_error
    end
  end

  describe "validated" do
    it "defaults to false" do
      expect(subject.validated).to be false
    end
  end

  describe "private methods" do
    describe "#_invalid_parameters" do
      context "during validation" do
        it "is the Array of parameters that are invalid" do
          subject.parameter :foo
          subject.parameter :bar, required: true
          subject.foo = "foo"
          subject.validating = true
          expect(subject.send(:_invalid_parameters)).
            to eq [{ name: "bar", options: { required: true }, value: nil, set: false }]
        end
      end
    end
  end
end
