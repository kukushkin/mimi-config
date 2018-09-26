# frozen_string_literal: true

# Returns the path to the manifest file
#
# @return [Pathname]
#
def rake_task_config_manifest_filename
  Mimi.app_path_to('config', 'manifest.yml')
end

# Displays current manifest and configured values in .env format
#
# @param include_consts [true,false] include non-configurable parameters (consts)
#
def rake_task_config(include_consts = false)
  manifest = Mimi::Config.load_manifest(rake_task_config_manifest_filename)
  missing_params = manifest.keys.select { |k| manifest.required?(k) }.reject { |k| ENV.key?(k.to_s) }

  manifest.to_h.each do |name, props|
    next if props[:const] && !include_consts
    annotation = []
    if props[:const]
      annotation << '[CONST]'
      annotation << "(value: #{props[:default].inspect})"
    elsif missing_params.include?(name)
      annotation << "[MISSING] (#{props[:type]})"
    else
      annotation << "(#{props[:type]}, default: #{props[:default].inspect})"
    end
    annotation << props[:desc] if props.key?(:desc)
    annotation.unshift('  #') unless annotation.empty?
    puts "#{name}=#{ENV[name.to_s]}#{annotation.join(' ')}"
  end
  abort('# FIXME: configure missing parameters') unless missing_params.empty?
end

# Generates a new/updated config manifest
#
# @return [String] a config manifest in the YAML format
#
def rake_task_config_manifest_generate
  manifest = Mimi::Core::Manifest.new({})

  # merge loaded modules manifests
  Mimi.loaded_modules.map(&:manifest).each do |manifest_hash|
    manifest.merge!(manifest_hash)
  end

  # merge app's explicit manifest
  app_manifest = Mimi::Config.load_manifest(rake_task_config_manifest_filename)
  manifest.merge!(app_manifest)

  manifest.to_yaml
end

desc 'Display config manifest and current config'
task :config do
  rake_task_config(false)
end

namespace :config do
  desc 'Display config manifest and current config, including consts'
  task :all do
    rake_task_config(true)
  end

  desc 'Generate and display a combined manifest for all loaded modules'
  task :manifest do
    puts rake_task_config_manifest_generate
  end

  namespace :manifest do
    manifest_filename = Pathname.pwd.join('config', 'manifest.yml')
    desc "Generate and write a combined manifest to: #{manifest_filename}"
    task :create do
      if File.exist?(manifest_filename)
        puts "* Found an existing application manifest, loading: #{manifest_filename}"
      end
      puts '* Generating a combined manifest'
      manifest_contents = rake_task_config_manifest_generate
      config_path = Mimi.app_path_to('config')
      puts "* Writing the combined manifest to: #{manifest_filename}"
      sh "install -d #{config_path}" unless File.directory?(config_path)
      File.open(rake_task_config_manifest_filename, 'w') do |f|
        f.puts manifest_contents
      end
    end
  end
end
