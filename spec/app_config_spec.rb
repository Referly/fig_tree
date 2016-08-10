require "spec_helper"

describe AppConfig do
  describe "configuring AppConfig" do
    describe ".configure" do
      it "yields AppConfig to the given block" do
        expect { |b| described_class.configure(&b) }.to yield_with_args AppConfig::ConfigurationContainer
      end

      it "is where you should specify the configuration parameters" do
        described_class.configure do |c|
          c.parameter :fooz
          c.parameter :doggyz, required: true
        end

        described_class.fooz = "yo fooz"
        expect { described_class.ready }.to raise_error AppConfig::MissingConfigurationError
        described_class.doggyz = "pups"
        expect { described_class.ready }.not_to raise_error

        described_class.ready

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
          described_class.ready
        }.to yield_with_args AppConfig::ConfigurationContainer
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
        described_class.ready

        expect(described_class.is_a_poodle).to eq false

        described_class.doggyz = "poodle"
        described_class.ready
        expect(described_class.is_a_poodle).to eq true
      end

      context "when .configure is called more than once" do
        it "resets the configuration each time" do
          described_class.configure do |c|
            c.parameter :cats
            expect(c).to respond_to :cats, :cats=
          end

          described_class.configure do |c|
            c.parameter :mice
            expect(c).to respond_to :mice, :mice=
            expect(c).not_to respond_to :cats, :cats=
          end
        end
      end

      describe "marking a configuration parameter as required" do
        it "accepts a :required option" do
          described_class.configure do |c|
            c.parameter :foo, required: true
          end
        end

        it "requires the parameter for the AppConfig to be valid" do
          described_class.configure do |c|
            c.parameter :foo, required: true
          end

          expect { described_class.ready }.to raise_error AppConfig::MissingConfigurationError

          described_class.foo = :bar

          expect { described_class.ready }.not_to raise_error
        end
      end
    end
  end

  describe "lifecycle events" do
    describe "ready" do
      context "before the ready lifecycle event" do
        it "prohibits reader access outside of the .configure block's scope" do
          described_class.configure do |c|
            c.parameter :foo
          end
          described_class.foo = "foo"
          expect { described_class.foo }.to raise_error NoMethodError
          expect(described_class).not_to respond_to :foo
          described_class.ready
          expect(described_class.foo).to eq "foo"
          expect(described_class).to respond_to :foo
        end

        it "permits reader access outside of the .configure block's scope during validation" do
          described_class.configure do |c|
            c.parameter :foo
          end
          described_class.foo = "foo"

          described_class.configuration.validating = true
          expect(described_class.foo).to eq "foo"
          expect(described_class).to respond_to :foo
        end
      end
    end
  end
  describe "callbacks" do
    context "when validation is successful" do
      it "invokes the registered callbacks in the order they were registered" do
        described_class.configure do |c|
          c.parameter :is_a_poodle
          c.parameter :doggyz, required: true
          c.after_validation do |validated_app_config|
            validated_app_config.is_a_poodle = validated_app_config.doggyz == "poodle"
          end
          c.after_validation do |validated_app_config|
            validated_app_config.doggyz = "buy a new dog" if validated_app_config.is_a_poodle
          end
        end

        described_class.doggyz = "poodle"
        described_class.is_a_poodle = false

        described_class.ready

        expect(described_class.is_a_poodle).to be true
        expect(described_class.doggyz).to eq "buy a new dog"
      end
    end
  end
end
