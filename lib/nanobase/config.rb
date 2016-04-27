require 'pathname'
require 'yaml'
require 'dotenv'

module Nanobase
  #
  # Config stores the manifest and reads and stores configurable parameters from ENV.
  #
  # @see README.md
  #
  class Config
    # Current set of values for configurable parameters
    attr_reader :params

    DEFAULT_OPTS = {
      raise_on_missing_params: true,
      use_dotenv: true
    }.freeze

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
      @manifest = {}
      @params = {}
      load(manifest_filename, opts) if manifest_filename
    end

    # Loads and parses manifest.yml, reads and sets configurable parameters
    # from ENV.
    #
    def load(manifest_filename, opts = {})
      opts = DEFAULT_OPTS.merge(opts)
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

    # Returns the parameter value
    #
    # @param key [String,Symbol] parameter name
    #
    def [](key)
      raise ArgumentError, "Undefined parameter '#{key}'" unless @manifest.key?(key.to_sym)
      @params[key.to_sym]
    end

    def respond_to_missing?(name, *)
      @manifest.key?(name) || super
    end

    # def respond_to?(name, *)
    #   @manifest.key?(name) || super
    # end

    def method_missing(name, *)
      return self[name] if @manifest.key?(name)
      puts "Not a declared parameter: #{name}"
      super
    end

    private

    # Reads manifest file and merges it with the current manifest.
    #
    def load_manifest(filename, _opts = {})
      new_manifest = YAML.load(File.read(filename))
      return manifest unless new_manifest
      raise 'Invalid manifest file format' unless new_manifest.is_a?(Hash)
      new_manifest.each do |k, v|
        merge_manifest_key(k, v)
      end
      manifest
    rescue StandardError => e
      raise "Failed to load manifest file: #{e}"
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

    def merge_manifest_key(k, v)
      k = k.to_sym
      @manifest[k] ||= {}
      if v.nil?
        # var:
      elsif v.is_a?(String)
        # var: A description
        @manifest[k][:desc] = v
      elsif v.is_a?(Hash)
        merge_manifest_key_hash(k, v)
      end
    end

    def merge_manifest_key_hash(k, v)
      @manifest[k][:desc] = v['desc'] if v.key?('desc')

      if v.key?('const') && v.key?('default')
        raise "Invalid mix of 'const' and 'default' in parameter definition '#{k}'"
      end

      if v.key?('default')
        @manifest[k][:const] = false
        @manifest[k][:default] = v['default']
      elsif v.key?('const')
        @manifest[k][:const] = true
        @manifest[k][:default] = v['const']
      end
    end
  end # class Config
end # module Nanobase

require_relative 'config/version'
