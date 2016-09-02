require 'yaml'
require 'erb'

require 'settler/typecaster'
require 'settler/typecasters/boolean_typecaster'
require 'settler/typecasters/datetime_typecaster'
require 'settler/typecasters/float_typecaster'
require 'settler/typecasters/integer_typecaster'
require 'settler/typecasters/password_typecaster'

require 'settler/string_inquirer'
require 'settler/abstract_setting'

# Settler loads and manages application wide settings and provides an interface for retrieving settings. The Settler
# object cannot be instantiated; all functionality is available on class level.
module Settler

  class << self
    attr_accessor  :config, :raise_missing, :report_missing, :typecast_on_write, :password_secret
    attr_writer    :orm, :namespace, :source

    # Loads the settler configuration from settler.yml and defines methods for retrieving the found settings.
    def load!
      raise "Source settler.yml not set. Please create one and set it by using Settler.source = <file>. When using Rails, please create a settler.yml file in the config directory." unless source

      self.config = File.exist?(source) ? YAML.load(ERB.new(File.read(source)).result).to_hash : {}
      self.config = config[namespace] || {} if namespace

      setting_class.build_settings! config
      setting_class.all.each{ |s| key = s.key; Settler.class.send(:define_method, key){ setting_for(key) } unless Settler.class.respond_to?(key) }
    end

    # Resets settler, useful for testing
    def reset!
      @orm = @namespace = @source = @setting_class = nil
      self.config = nil
      self.raise_missing = nil
      self.report_missing = nil
      self.typecast_on_write = nil
      self.password_secret = nil
    end

    # Shortcut method for quickly retrieving settings. This method directly returns the setting's value instead of the Setting instance.
    def [](key)
      ensure_config_loaded!
      if setting = setting_for(key.to_s)
        setting.value
      end
    end

    # Returns the setting object for a given key
    def setting_for(key)
      ensure_config_loaded!
      setting_class.find_by_key(key.to_s)
    end

    # Returns an array of all setting keys
    def settings(options = {})
      ensure_config_loaded!
      setting_class.all_keys(options)
    end

    # Returns a list of validations to perform on a setting.
    def validations_for(key)
      ensure_config_loaded!
      if setting = config[key.to_s]
        setting['validations'] || {}
      else
        {}
      end
    end

    # Returns the typecast for a setting (if any).
    def typecast_for(key)
      ensure_config_loaded!
      if setting = config[key.to_s]
        setting['typecast']
      end
    end

    # Overrides the normal method_missing to return nil for non-existant settings. The behaviour of this method
    # depends on the boolean attributes raise_missing and report_missing.
    def method_missing(name, *args, &block)
      method_name = name.to_s
      return super if Settler.private_methods(false).map(&:to_s).include?(method_name)

      if config.nil?
        Settler.load!
        return send(method_name)
      end

      warn  "[Settler] Warning: setting missing: #{method_name}"  if report_missing
      raise "[Settler] Error: setting missing: #{method_name}"    if raise_missing

      nil
    end

    # Returns whether Settler runs in persistent or transient mode
    def orm
      @orm ||= begin
        if defined?(ActiveRecord::Base) && ActiveRecord::Base.connected? && Setting.table_exists?
          :activerecord
        else
          :ruby
        end
      end
    end

    # Returns the used setting class
    def setting_class
      @setting_class ||= case orm
      when :activerecord
        require 'settler/orm/activerecord/setting'
        Settler::ORM::Activerecord::Setting
      else
        require 'settler/orm/ruby/setting'
        Settler::ORM::Ruby::Setting
      end
    end

    # Returns the file location of the settler.yml configuration file. Defaults to
    # the 'config/settler.yml' if the library is included in a Rails app.
    def source
      @source ||= File.join(Rails.root, 'config', 'settler.yml') if defined?(Rails)
      @source
    end

    # Returns the namespace of the configuration to look for settings. Defaults to
    # the current Rails environment if the library is included in a Rails app.
    def namespace
      @namespace ||= Rails.env if defined?(Rails)
      @namespace
    end

    protected

    def warn warning
      puts warning
      Rails.logger.warn(warning) if defined?(Rails)
    end

    private

    def ensure_config_loaded!
      Settler.load! if config.nil?
    end

  end

end
