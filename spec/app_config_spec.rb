require "spec_helper"

describe AppConfig do
  describe "configuring AppConfig" do
    describe ".configure" do
      it "yields AppConfig to the given block" do
        expect { |b| described_class.configure(&b) }.to yield_with_args described_class
      end

      it "is where you should specify the configuration parameters" do
        described_class.configure do |c|
          c.parameter :fooz
          c.parameter :doggyz, required: true
        end

        described_class.fooz = "yo fooz"
        expect { described_class.valid? }.to raise_error AppConfig::MissingConfigurationError
        described_class.doggyz = "pups"
        expect { described_class.valid? }.not_to raise_error

        expect(described_class.fooz).to eq "yo fooz"
        expect(described_class.doggyz).to eq "pups"
      end

      it "is where you should specify after_validation callbacks" do
        expect { |b|
          described_class.configure do |c|
            c.parameter :doggyz, required: true
            c.after_validation(&b)
          end
          described_class.doggyz = "poodle"
          described_class.valid?
        }.to yield_with_args described_class
      end

      it "is possible to perform actions based on the latest state of the AppConfig" do
        described_class.configure do |c|
          c.parameter :is_a_poodle
          c.parameter :doggyz, required: true
          c.after_validation do |validated_app_config|
            validated_app_config.is_a_poodle = validated_app_config.doggyz == "poodle"
          end
        end

        described_class.doggyz = "collie"
        described_class.valid?
        expect(described_class.is_a_poodle).to eq false

        described_class.doggyz = "poodle"
        described_class.valid?
        expect(described_class.is_a_poodle).to eq true
      end
    end
  end
  describe "adding a configuration parameter" do
    describe ".parameter" do
      it "adds a configuration parameter to AppConfig" do
        described_class.parameter :foo

        described_class.foo = nil

        expect(described_class.foo).to be nil

        described_class.foo = :bar

        expect(described_class.foo).to eq :bar
      end

      describe "marking a configuration parameter as required" do
        it "accepts a :required option" do
          described_class.parameter :foo, required: true
        end

        it "requires the parameter for the AppConfig to be valid" do
          described_class.parameter :foo, required: true

          described_class.foo = nil

          expect { described_class.valid? }.to raise_error AppConfig::MissingConfigurationError

          described_class.foo = :bar

          expect { described_class.valid? }.not_to raise_error
        end
      end
    end
  end
end
