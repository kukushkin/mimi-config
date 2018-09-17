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

    # Mimi::Config module manifest
    #
    def self.manifest
      {
        config_raise_on_missing_params: {
          desc: 'Raise error on missing params',
          default: true,
          hidden: true
        },
        config_use_dotenv: {
          desc: 'Use Dotenv and load .env file',
          default: true,
          hidden: true
        }
      }
    end

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
      @manifest = Mimi::Core::Manifest.new({})
      @params = {}
      load(manifest_filename, opts) if manifest_filename
    end

    # Loads and parses manifest.yml, reads and sets configurable parameters
    # from ENV.
    #
    def load(manifest_filename, opts = {})
      opts = self.class.options.deep_merge(opts)
      manifest_filename = Pathname.new(manifest_filename).expand_path
      load_manifest(manifest_filename, opts)
      load_params(opts)
      if opts[:config_raise_on_missing_params] && !missing_params.empty?
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
      @manifest.to_h
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
      @manifest.to_h.key?(name.to_sym)
    end

    # Returns the parameter value
    #
    # @param key [Symbol] parameter name
    #
    def [](key)
      unless key.is_a?(Symbol)
        raise ArgumentError, "Invalid key to #[], Symbol expected: '#{key.inspect}'"
      end
      raise ArgumentError, "Undefined parameter '#{key}'" unless include?(key)
      @params[key]
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
      @manifest.to_h.keys.map do |k|
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
      @manifest.merge!(parse_manifest_file(filename))
    rescue StandardError => e
      raise "Failed to load config manifest from '#{filename}': #{e}"
    end

    # Reads manifest from a given file, and parses it to a standard manifest Hash
    #
    # @param filename [String]
    # @return [Hash]
    #
    def parse_manifest_file(filename)
      manifest_hash = YAML.load(File.read(filename))
      raise 'Invalid manifest, JSON Object is expected' unless manifest_hash.is_a?(Hash)
      manifest_hash.map do |k, v|
        v = (v || {}).symbolize_keys
        [k.to_sym, v]
      end.to_h
    end

    # Reads parameters from the ENV according to the current manifest
    #
    def load_params(opts = {})
      Dotenv.load if opts[:config_use_dotenv]
      @params = @manifest.apply(ENV.to_h.symbolize_keys)
    end
  end # class Config
end # module Mimi

require_relative 'config/version'
