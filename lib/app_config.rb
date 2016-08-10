class AppConfig
  MissingConfigurationError = Class.new StandardError
  DuplicateParameterDefinitionError = Class.new StandardError

  class << self
    attr_accessor :configuration

    # And we define a wrapper for the configuration block, that we'll use to set up
    # our set of options
    def configure
      @configuration = ConfigurationContainer.new
      @configuration.configuring = true
      yield configuration if block_given?
      @configuration.configuring = false
    end

    def configuration
      @configuration ||= ConfigurationContainer.new
    end

    def method_missing(method_name, *args, &blk)
      return super unless configuration.respond_to? method_name
      configuration.send method_name, *args, &blk
    end

    def respond_to_missing?(method, _include_private = false)
      configuration.respond_to?(method) || super
    end
  end

  class ConfigurationContainer
    attr_accessor :parameters,
                  :after_validation_callbacks,
                  :configuring,
                  :validating,
                  :readied, # set to true during the ready lifecycle event
                  :validated # set to true during the validation lifecycle event

    def initialize
      @configuring = false
      @validating = false
    end

    def parameter(name, options = {})
      @parameters ||= []
      raise DuplicateParameterDefinitionError if parameters.any? { |p| p.keys.first == name }
      parameters << { name: name.to_s, options: options, value: nil }
    end

    def valid?
      @validating = true
      _missing_configuration if _invalid_parameters.any?
      Array(@after_validation_callbacks).each do |callback|
        callback.call self
      end
      # Below line is the final_validation lifecycle event
      _missing_configuration if _invalid_parameters.any?
      @validated = true
      @validating = false
      @validated
    end

    def validated
      @validated ||= false
    end

    def ready
      valid?
      @readied = true
    end

    def readied
      @readied ||= false
    end

    def after_validation(&blk)
      @after_validation_callbacks ||= []
      @after_validation_callbacks << blk
    end

    def method_missing(method_name, *args, &blk)
      method_name_str = method_name.to_s
      return super unless _dynamically_exposed_methods.include? method_name_str
      if _dynamically_exposed_readers.include? method_name_str
        parameters.detect { |p| p[:name] == method_name_str }[:value]
      elsif _dynamically_exposed_writers.include? method_name_str
        parameters.detect { |p| "#{p[:name]}=" == method_name_str }[:value] = args.first
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      _dynamically_exposed_methods.include?(method_name.to_s) || super
    end

    private

    def _missing_configuration
      raise MissingConfigurationError,
            "All required configurations have not been set. Missing configurations: #{_invalid_parameter_names}"
    end

    def _dynamically_exposed_methods
      _dynamically_exposed_readers | _dynamically_exposed_writers
    end

    def _dynamically_exposed_readers
      (readied || configuring || validating) ? parameters.map { |p| p[:name] } : []
    end

    def _dynamically_exposed_writers
      parameters.map { |p| "#{p[:name]}=" }
    end

    def _invalid_parameters
      parameters.
        select { |p| p[:options].fetch(:required, false) }.
        select { |p| send(p[:name]).nil? }
    end

    def _invalid_parameter_names
      _invalid_parameters.map { |p| p[:name] }.join(",")
    end
  end
end
