# Nanobase::Config

A simple ENV based configuration for microservice applications.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nanobase-config'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nanobase-config

## Usage

`Nanobase::Config` allows you to define a set of configurable parameters and constants in a *manifest* file with a simple YAML format.

### Example manifest.yml
```yaml,name=manifest.yml
opt1:
  desc: This is an optional configurable parameter
  default: 123

opt2:
  desc: This is an optional configurable parameter with the default value of nil
  default:

const1:
  desc: This is a constant parameter, that cannot be changed via an ENV variable
  const: 456


req1: This is a required configurable parameter

req2:
  desc: And so is this one

# And so is this one with no description
req3:
```

### How to load configuration from your app

Providing you placed your manifest into `config/manifest.yml`:

```
config = Nanobase::Config.new('config/manifest.yml')

config.const1 # => 456, from manifest.yml
config.opt1 # value from ENV['opt1'] or default from manifest.yml
config.req2 # value from ENV['req2']
config.req5 # => NoMethodError, for any parameter not defined in manifest
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/nanobase-config. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

