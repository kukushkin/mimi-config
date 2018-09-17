require 'bundler/setup'
Bundler.setup
$LOAD_PATH.unshift(__dir__)

require_relative '../lib/mimi/config'
require 'support/fixtures'
require 'support/env_vars'


RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
