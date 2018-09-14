# mimi-config

A simple ENV and manifest based configuration for microservice applications.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mimi-config'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mimi-config

## Usage

`Mimi::Config` allows you to define a set of configurable parameters and constants in a *manifest* file with a simple YAML format.

When instantiated, a `Mimi::Config` object reads and parses the manifest found in the specified file,
loads parameter values from ENV variables and processes them according to the manifest.

On success, `Mimi::Config` object makes configurable parameters available as Hash keys
or as methods:

```yaml
# manifest.yml
param1:
  default: "foobar"
```

```ruby
require 'mimi/config'

config = Mimi::Config.new('manifest.yml')
config.param1 # => "foobar", if ENV['param1'] is not set
```


## Manifest

A *manifest* is a formal declaration of accepted configurable parameters.
Only the parameters defined in the manifest may be set.

For each configurable parameter there may be declared:

 * configurable parameter name
 * human readable description of the parameter
 * type of accepted values
 * default value
 * whether this parameter is constant or not

### Example manifest.yml
```yaml,name=manifest.yml
# This is a minimal definition of a configurable parameter.
# Its type is 'string', there is no human readable description and no default value:
min1:

# This parameter is optional as it has a default value.
opt1:
  desc: This is an optional configurable parameter
  default: "opt1.default"

# Having no defined default value makes the configurable parameter required
req1:
  desc: This is a required configurable parameter

# An optional configurable parameter with a default value of 'nil':
opt2:
  default:

# A constant parameter of type 'string'.
# It must have a default value and it cannot be changed via ENV variable.
const1:
  desc: This is a constant parameter
  default: "const1.default"
  const: true
```

### Configurable parameter types

The type of configurable parameter defines which values/format it accepts from ENV,
and the type it converts the processed value to.

```yaml
# manifest_with_types.yml

# 'string' accepts any value and converts to String
str1:
  type: string

# 'integer' accepts any positive integer and converts to Integer
int1:
  type: integer

# 'decimal' accepts a decimal number representation (integer or fractional) and converts to BigDecimal
dec1:
  type: decimal

# 'boolean' accepts only String values 'true' and 'false',
# and converts to Ruby literals 'true' or 'false'.
bool1:
  type: boolean

# 'json' accepts a valid JSON and converts to a decoded object (of any type)
json1:
  type: json

# 'enum' is a special type that accepts only values from a provided set of string literals.
# Converts the value to String.
enum1:
  type:
    - debug
    - info
    - warn
    - error
```

**Example:**

```ruby
require 'mimi/config'

# Provided the ENV values are set as:
ENV['str1'] # => "foobar"
ENV['int1'] # => "123"
ENV['dec1'] # => "1.23"
ENV['bool1'] # => "true"
ENV['json1'] # => "[{\"a\":1},{\"b\":2}]"
ENV['enum1'] # => "info"

config = Mimi::Config.new('manifest_with_types.yml')

config.str1 # => "foobar" (String)
config.int1 # => 123 (Integer)
config.dec1 # => 1.23 (BigDecimal)
config.bool1 # => true (TrueClass)
config.json1 # => [{"a"=>1}, {"b"=>2}] (Array)
config.enum1 # => "info" (String)
```


### How to load configuration from your app

Providing you have placed your manifest into `config/manifest.yml`:

```yaml
const1:
  default: 456
  const: true

req1:

opt1:
  default: foobar

opt2:
  type: integer
  default: 0
```

```ruby
config = Mimi::Config.new('config/manifest.yml')

config.const1 # => 456, from manifest.yml
config.opt1 # value from ENV['opt1'] or default "foobar" from manifest.yml
config.req2 # value from ENV['req2']

# alternatively use [] syntax:
config.opt2    #
config[:opt2]  # refers to the same configurable parameter

# you cannot access parameters not defined in the manifest:
config.foobar # => NoMethodError
config[:foobar] # => ArgumentError

# when using [] syntax, use Symbol as parameter name:
config.opt2     # => 0, if ENV['opt2'] is not set
config[:opt2]   # => 0, if ENV['opt2'] is not set
config['opt2']  # => ArgumentError

# check, if parameter is defined:
config.include?(:foobar) # => false
```

### Using with Dotenv

When a `Mimi::Config` object is instantiated, the `.env` file is loaded and processed,
the functionality provided by the `dotenv` gem.

You can choose to disable `dotenv` and `.env` file loading:

```ruby
require 'mimi/config'

config = Mimi::Config.new('manifest.yml', config_use_dotenv: false)
```

### Using as Mimi component

It is possible to configure `Mimi::Config` as a Mimi module:

```ruby
require 'mimi/config'

Mimi.use Mimi::Config, config_use_dotenv: false
```

After that, any `Mimi::Config` object you instantiate will use provided options as default.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

