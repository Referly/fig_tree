# FigFig
Ruby Application Configurator with some validation support

[![CircleCI](https://circleci.com/gh/Referly/fig_fig.svg?style=svg)](https://circleci.com/gh/Referly/fig_fig)

## Usage

Follow this example to perform basic configuration and validation of
parameter presence.

```ruby
require "fig_fig"
FigFig.configure do |c|
    c.parameter :foo
    c.parameter :bar, required: true
end
FigFig.foo = "foodog"
FigFig.ready
#=> raises FigFig::MissingConfigurationError
FigFig.bar = "yum beer"
FigFig.ready
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
require "fig_fig"
FigFig.configure do |c|
    c.parameter :foo    
end
FigFig.foo = "foo"
FigFig.ready
FigFig.foo
# => "foo"
FigFig.foo = bar
FigFig.foo
# => "bar"
FigFig.configure do |c|
    c.parameter :baz    
end
# => raises ConfigurationAlreadyDefinedError
FigFig.configure(reset: true) do |c|
    c.parameter :baz    
end
FigFig.foo = "foo"
# => raises NoMethodError
```

You can immediately read values for parameters inside of the block passed to 
 `.configure`. However, you need to call `.ready` when you are done with your 
 configuration process and before your application can read values for 
 parameters from the configuration.

```ruby
require "fig_fig"
FigFig.configure do |c|
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
this is useful for late binding configuration parameters managed by FigFig
to other gems that use the conventional .configure approach.

(Note that after_validation callbacks are invoked in the order they are set.)

```ruby
require "fig_fig"
FigFig.configure do |c|
  c.parameter :is_a_poodle
  c.parameter :doggyz, required: true
  c.after_validation do |validated_fig_fig|
    validated_fig_fig.is_a_poodle = validated_fig_fig.doggyz == "poodle"
  end
end
FigFig.doggyz = "collie"
FigFig.ready
FigFig.is_a_poodle
# => false
FigFig.doggyz = "poodle"
FigFig.ready
FigFig.is_a_poodle
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
require "fig_fig"
FigFig.configure do |c|
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
# => raises FigFig::CannotModifyLockedParameterError
c.doz = "doz2"
c.eck = "eck2"
FigFig.valid?
c.foo = "foo3"
c.bar = "bar3"
# => raises FigFig::CannotModifyLockedParameterError
c.doz = "doz3"
# => raises FigFig::CannotModifyLockedParameterError
c.diz = "diz"
# => raises FigFig::CannotModifyLockedParameterError
c.diz
# => nil
c.eck = "eck3"
FigFig.ready
c.foo = "foo4"
c.bar = "bar4"
# => raises FigFig::CannotModifyLockedParameterError
c.doz = "doz4"
# => raises FigFig::CannotModifyLockedParameterError
c.diz = "diz2"
# => raises FigFig::CannotModifyLockedParameterError
c.diz
# => nil
c.eck = "eck4"
# => raises FigFig::CannotModifyLockedParameterError
c.exz = "exz"
# => raises FigFig::CannotModifyLockedParameterError
c.exz
# => nil
```

## Lifecycle events

- `validation` - when the valid? method is invoked (you can register callbacks to `#after_validation`)

- `final_validation` - you cannot interact with this internal only lifecycle event which performs a second
validation pass after the after_validation callbacks have been run to make sure the configuration is still valid.

- `ready` - when the FigFig instance has completed its bootstrapping process and is ready to be
used by your application. Late immutable parameters are locked at this point and can no longer be changed
via setters. (currently you cannot register callbacks to `before_ready` or `after_ready`)
