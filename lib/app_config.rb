module AppConfig
  class MissingConfigurationError < StandardError; end
  # Appdata provides a basic single-method DSL with .parameter method
  # being used to define a set of available settings.
  # This method takes one or more symbols, with each one being
  # a name of the configuration option.
  attr_accessor :__required_parameters__

  def parameter(name, options = {})
    attr_accessor name
    module_function name
    module_function "#{name}="
    @__required_parameters__ ||= []
    @__required_parameters__ << name if options[:required]
  end

  # And we define a wrapper for the configuration block, that we'll use to set up
  # our set of options
  def configure
    yield self if block_given?
  end

  def valid?
    _, unset = @__required_parameters__.partition { |p| !public_send(p).nil? }
    raise MissingConfigurationError,
          "All required configurations have not been set. Missing configurations: #{unset.join(',')}" if unset.any?
  end

  module_function :configure, :parameter, :valid?
end
