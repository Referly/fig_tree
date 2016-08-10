# app_config
Ruby Application Configurator with some validation support

## Usage

Follow this example to perform basic configuration and validation of
parameter presence.

```ruby
require "app_config"
AppConfig.configure do |c|
    c.parameter :foo
    c.parameter :bar, required: true
end
AppConfig.foo = "foodog"
AppConfig.valid?
#=> raises AppConfig::MissingConfigurationError
AppConfig.bar = "yum beer"
AppConfig.valid?
# => nil
```

You can specify blocks that should be executed after validation is successful,
this is useful for late binding configuration parameters managed by AppConfig
to other gems that use the conventional .configure approach.

(Note that after_validation callbacks are invoked in the order they are set.)

```ruby
require "app_config"
AppConfig.configure do |c|
  c.parameter :is_a_poodle
  c.parameter :doggyz, required: true
  c.after_validation do |validated_app_config|
    validated_app_config.is_a_poodle = validated_app_config.doggyz == "poodle"
  end
end
AppConfig.doggyz = "collie"
AppConfig.valid?
AppConfig.is_a_poodle
# => false
AppConfig.doggyz = "poodle"
AppConfig.valid?
AppConfig.is_a_poodle
# => true
```