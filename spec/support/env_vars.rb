require 'dotenv'

# Runs block with ENV variables loaded from specified .env file or a Hash,
# restores original ENV variables after.
#
# @example
#   with_env_vars('.env.test') do
#     application.config.load
#   end
#
#   # OR:
#
#   with_env_vars(var1: 'abc') do
#     application.config.load
#   end
#
def with_env_vars(filename_or_vars = {}, &_block)
  original_env_vars = ENV.to_hash
  if filename_or_vars.is_a?(Hash)
    filename_or_vars.each { |k, v| ENV[k.to_s] = v }
  else
    Dotenv.load(filename) if filename
  end
  yield
ensure
  ENV.replace(original_env_vars)
end
