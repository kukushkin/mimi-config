module Mimi
  class Config
    class Manifest < Hash
      # Reads manifest file and merges it with the current manifest.
      #
      # @return [Mimi::Config::Manifest] current manifest merged with the new one
      #
      def load(filename_or_hash, _opts = {})
        new_manifest = nil
        if filename_or_hash.is_a?(String) || filename_or_hash.is_a?(Pathname)
          new_manifest = YAML.load(File.read(filename_or_hash))
        end
        new_manifest = filename_or_hash.dup if filename_or_hash.is_a?(Hash)
        return self unless new_manifest
        raise 'Invalid manifest file format' unless new_manifest.is_a?(Hash)
        new_manifest.each do |k, v|
          merge_key(k, v)
        end
        self
      rescue StandardError => e
        raise "Failed to load manifest file: #{e}"
      end

      # Returns YAML representation of the manifest
      #
      # @return [String]
      #
      def to_yaml
        out = []
        self.each do |k, v|
          if v.key?(:const)
            out << "#{k}:"
            out << "  desc: #{value_to_yaml(v[:desc])}" if v.key?(:desc)
            if v[:const]
              out << "  const: #{value_to_yaml(v[:default])}"
            elsif v.key?(:default)
              out << "  default: #{value_to_yaml(v[:default])}"
            end
          elsif v.key?(:desc)
            out << "#{k}: #{value_to_yaml(v[:desc])}"
          else
            out << "#{k}:"
          end
          out << ''
        end
        out.join("\n")
      end

      private

      def value_to_yaml(v)
        v.nil? ? '# nil' : v.inspect
      end

      def merge_key(k, v)
        k = k.to_sym
        self[k] ||= {}
        if v.nil?
          # var:
        elsif v.is_a?(String)
          # var: A description
          self[k][:desc] = v
        elsif v.is_a?(Hash)
          merge_key_hash(k, v)
        end
      end

      def merge_key_hash(k, v)
        v = v.dup.stringify_keys
        self[k][:desc] = v['desc'] if v.key?('desc')

        if v.key?('const') && v.key?('default')
          raise "Invalid mix of 'const' and 'default' in parameter definition '#{k}'"
        end

        if v.key?('default')
          self[k][:const] = false
          self[k][:default] = v['default']
        elsif v.key?('const')
          self[k][:const] = true
          self[k][:default] = v['const']
        end
      end
    end # class Manifest
  end # class Config
end # module Mimi
