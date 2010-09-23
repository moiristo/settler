class SettlerGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    runtime_args << 'Settler' if runtime_args.empty?
    super
  end

  def manifest
    record do |m|
      m.file "settler.yml", "config/settler.yml"
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => 'add_settings_table'
    end
  end
end