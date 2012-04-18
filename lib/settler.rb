require 'yaml'
require 'erb'
require 'hash_extension'
require 'type_casters'
require 'setting'

# Settler loads and manages application wide settings and provides an interface for retrieving settings. The Settler
# object cannot be instantiated; all functionality is available on class level.
class Settler
  private_class_method :new
  cattr_accessor  :config, :raise_missing, :report_missing, :typecast_on_write, :password_secret
  cattr_writer    :namespace, :source

  class << self
    # Loads the settler configuration from settler.yml and defines methods for retrieving the found settings.
    def load!    
      raise "Source settler.yml not set. Please create one and set it by using Settler.source = <file>. When using Rails, please create a settler.yml file in the config directory." unless source
      
      self.config = YAML.load(ERB.new(File.read(source)).result).to_hash
      self.config = config[namespace] if namespace
      self.config.each do  |key, attributes| 
        Setting.without_default_scope do 
          setting = Setting.find_or_create_by_key(:key => key) do |s|
             s.alt = attributes['alt']
             s.value = attributes['value']             
             s.editable = attributes['editable']
             s.deletable = attributes['deletable']
          end
          p "[Settler] Validation failed for setting '#{setting.key}': #{setting.errors.full_messages.to_sentence}" if !setting.valid?
        end 
      end
      Setting.all.each{ |s| key = s.key; Settler.class.send(:define_method, key){ Setting.find_by_key(key) } }
    end    
    
    # Shortcut method for quickly retrieving settings. This method directly returns the setting's value instead of the Setting instance. 
    def [](key)
      Settler.load! if config.nil?      
      Setting.find_by_key(key.to_s).try(:value)
    end
    
    # Returns an array of all setting keys
    def settings(options = {})
      Settler.load! if config.nil?
      Setting.all(:order => options[:order]).map(&:key)
    end  
    
    # Returns a list of validations to perform on a setting.
    def validations_for(key)
      setting_validations = {}
      Settler.load! if config.nil?
      (setting = config[key.to_s]) ? setting['validations'] || {} : {}
    end
    
    # Returns the typecast for a setting (if any).
    def typecast_for(key)
      Settler.load! if config.nil?
      (setting = config[key.to_s]) ? setting['typecast'] || nil : nil
    end    
    
    # Overrides the normal method_missing to return nil for non-existant settings. The behaviour of this method
    # depends on the boolean attributes raise_missing and report_missing.
    def method_missing(name, *args, &block)
      method_name = name.to_s      
      return super if Settler.private_methods(false).include?(method_name)
      
      if config.nil?
        Settler.load!
        return send(method_name)
      end
      
      if report_missing  
        puts "[Settler] Warning: setting missing: #{method_name}"     
        Rails.logger.warn("[Settler] setting missing: #{method_name}") if defined?(Rails)
      end
      
      raise "[Settler] setting missing: #{method_name}" if raise_missing
      
      nil
    end 
    
    # Returns the file location of the settler.yml configuration file. Defaults to 
    # the 'config/settler.yml' if the library is included in a Rails app.
    def source
      @@source ||= File.join(Rails.root, 'config', 'settler.yml') if defined?(Rails)
      @@source
    end
    
    # Returns the namespace of the configuration to look for settings. Defaults to 
    # the current Rails environment if the library is included in a Rails app.
    def namespace
      @@namespace ||= Rails.env if defined?(Rails)
      @@namespace
    end     
    
  end
  
end
