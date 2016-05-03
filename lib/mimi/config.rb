require 'pathname'
require 'yaml'
require 'dotenv'
require 'mimi/core'

module Mimi
  # Returns all loaded modules combined configuration manifest
  #
  def self.loaded_modules_manifest
    loaded_modules.reduce(Mimi::Config::Manifest.new) { |a, e| a.load(e.module_manifest) }
  end


  #
  # Config stores the manifest and reads and stores configurable parameters from ENV.
  #
  # @see README.md
  #
  class Config
    include Mimi::Core::Module

    # Current set of values for configurable and const parameters
    attr_reader :params

    default_options(
      raise_on_missing_params: true,
      use_dotenv: true
    )

    # Creates a Config object.
    #
    # Loads and parses manifest.yml, reads and sets configurable parameters
    # from ENV.
    #
    # Raises an error if any of the required configurable parameters are missing.
    #
    # @param manifest_filename [String,nil] path to the manifest.yml or nil to skip loading manifest
    #
    def initialize(manifest_filename = nil, opts = {})
      @manifest = Mimi::Config::Manifest.new
      @params = {}
      load(manifest_filename, opts) if manifest_filename
    end

    # Loads and parses manifest.yml, reads and sets configurable parameters
    # from ENV.
    #
    def load(manifest_filename, opts = {})
      opts = self.class.module_options.deep_merge(opts)
      manifest_filename = Pathname.new(manifest_filename).expand_path
      load_manifest(manifest_filename, opts)
      load_params(opts)
      if opts[:raise_on_missing_params] && !missing_params.empty?
        raise "Missing required configurable parameters: #{missing_params.join(', ')}"
      end
      self
    end

    # Returns list of missing required params
    #
    def missing_params
      required_params = manifest.select { |p| p[:required] }.map { |p| p[:name] }
      required_params - @params.keys
    end

    # Returns annotated manifest
    #
    def manifest
      @manifest.map do |k, v|
        {
          name: k,
          desc: v[:desc],
          required: !v.key?(:default),
          const: v[:const],
          default: v[:default]
        }
      end
    end

    # Returns raw manifest
    #
    def manifest_raw
      @manifest
    end

    # Returns true if the config manifest includes the parameter with the given name.
    #
    # If manifest includes the parameter name, it is safe to access paramter
    # via #[] and #<name> methods.
    #
    def include?(name)
      @manifest.key?(name.to_sym)
    end

    # Returns the parameter value
    #
    # @param key [String,Symbol] parameter name
    #
    def [](key)
      raise ArgumentError, "Undefined parameter '#{key}'" unless include?(key)
      @params[key.to_sym]
    end

    # Provides access to parameters as methods.
    #
    # Example:
    #   config['foo'] # => 'bar'
    #   config.foo # => 'bar'
    #
    #   # missing parameter
    #   config['bar'] # => ArgumentError
    #   config.bar # => NoMethodError
    #
    def method_missing(name, *)
      return self[name] if include?(name)
      super
    end

    def respond_to_missing?(name, *)
      include?(name) || super
    end

    # Returns Hash representation of the config.
    # All Hash keys are Symbol
    #
    # @return [Hash]
    #
    def to_h
      @manifest.keys.map do |k|
        [k, self[k]]
      end.to_h
    end

    # Returns to_h.to_s
    #
    def to_s
      to_h.to_s
    end

    private

    # Reads manifest file and merges it with the current manifest.
    #
    def load_manifest(filename, _opts = {})
      @manifest.load(filename)
    end

    # Reads parameters from the ENV according to the current manifest
    #
    def load_params(opts = {})
      Dotenv.load if opts[:use_dotenv]
      manifest.each do |p|
        env_name = p[:name].to_s
        if p[:const]
          # const
          @params[p[:name]] = p[:default]
        elsif p[:required]
          # required configurable
          @params[p[:name]] = ENV[env_name] if ENV.key?(env_name)
        else
          # optional configurable
          @params[p[:name]] = ENV.key?(env_name) ? ENV[env_name] : p[:default]
        end
      end
      @params
    end
  end # class Config
end # module Mimi

require_relative 'config/version'
require_relative 'config/manifest'
