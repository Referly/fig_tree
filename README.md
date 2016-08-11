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
AppConfig.ready
#=> raises AppConfig::MissingConfigurationError
AppConfig.bar = "yum beer"
AppConfig.ready
# => nil
```

If you call `.configure` a second time it raises a ConfigurationAlreadyDefinedError.
To reset the configuration definition so that it can be redefined pass the `reset: true` option
 to `.configure`. If you do supply the `reset: true` option, all existing parameter definitions 
 and any set values will be lost. This true regardless of the current lifecycle stage of the config. 
 
Despite the restriction against calling `.configure` more than once, callbacks you register in the
block passed to `.configure` can modify any parameter value (unless the parameter is locked),
read any parameter value, and even register additional parameters (advanced).

```ruby
require "app_config"
AppConfig.configure do |c|
    c.parameter :foo    
end
AppConfig.foo = "foo"
AppConfig.ready
AppConfig.foo
# => "foo"
AppConfig.foo = bar
AppConfig.foo
# => "bar"
AppConfig.configure do |c|
    c.parameter :baz    
end
# => raises ConfigurationAlreadyDefinedError
AppConfig.configure(reset: true) do |c|
    c.parameter :baz    
end
AppConfig.foo = "foo"
# => raises NoMethodError
```

You can immediately read values for parameters inside of the block passed to 
 `.configure`. However, you need to call `.ready` when you are done with your 
 configuration process and before your application can read values for 
 parameters from the configuration.

```ruby
require "app_config"
AppConfig.configure do |c|
    c.parameter :foo
    c.parameter = "foo"
    puts c.parameter
    # => "foo"
end
c.parameter
# => raises NoMethodError
c.ready
c.parameter
# => "foo"
```

You can check validity of the configuration without invoking `.ready` by
calling `.valid?`


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
AppConfig.ready
AppConfig.is_a_poodle
# => false
AppConfig.doggyz = "poodle"
AppConfig.ready
AppConfig.is_a_poodle
# => true
```

You can control the mutability level of the parameters you define. The gem syntax
exposes this functionality using the `:lock` option. The possible values are:

- nil (the default) - the parameter can be changed at any point
- :on_set - the parameter once set cannot be subsequently modified
- :on_validation - the parameter is locked during the validation lifecycle event and
before the after_validation callbacks are invoked
- :on_ready - the parameter is locked during the `ready` lifecycle event, the intended
use case is when you want to prevent the application from modifying the configuration
outside of the configuration bootstrapping stage of your application

```ruby
require "app_config"
AppConfig.configure do |c|
  c.parameter :foo
  c.parameter :bar, lock: :on_set
  c.parameter :doz, lock: :on_validation
  c.parameter :diz, lock: :on_validation
  c.parameter :eck, lock: :on_ready
  c.parameter :exz, lock: :on_ready
end
c.foo = "foo"
c.bar = "bar"
c.doz = "doz"
c.eck = "eck"
c.foo = "foo2"
c.bar = "bar2"
# => raises AppConfig::CannotModifyLockedParameterError
c.doz = "doz2"
c.eck = "eck2"
AppConfig.valid?
c.foo = "foo3"
c.bar = "bar3"
# => raises AppConfig::CannotModifyLockedParameterError
c.doz = "doz3"
# => raises AppConfig::CannotModifyLockedParameterError
c.diz = "diz"
# => raises AppConfig::CannotModifyLockedParameterError
c.diz
# => nil
c.eck = "eck3"
AppConfig.ready
c.foo = "foo4"
c.bar = "bar4"
# => raises AppConfig::CannotModifyLockedParameterError
c.doz = "doz4"
# => raises AppConfig::CannotModifyLockedParameterError
c.diz = "diz2"
# => raises AppConfig::CannotModifyLockedParameterError
c.diz
# => nil
c.eck = "eck4"
# => raises AppConfig::CannotModifyLockedParameterError
c.exz = "exz"
# => raises AppConfig::CannotModifyLockedParameterError
c.exz
# => nil
```

## Lifecycle events

- `validation` - when the valid? method is invoked (you can register callbacks to `#after_validation`)

- `final_validation` - you cannot interact with this internal only lifecycle event which performs a second
validation pass after the after_validation callbacks have been run to make sure the configuration is still valid.

- `ready` - when the AppConfig instance has completed its bootstrapping process and is ready to be
used by your application. Late immutable parameters are locked at this point and can no longer be changed
via setters. (currently you cannot register callbacks to `before_ready` or `after_ready`)
