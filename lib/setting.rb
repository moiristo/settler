require 'type_casters'

# The Setting class is an AR model that encapsulates a Settler setting. The key if the setting is the only required attribute.\
class Setting < ActiveRecord::Base  
  cattr_accessor :rails3
  self.rails3 = defined?(ActiveRecord::VERSION) && ActiveRecord::VERSION::MAJOR >= 3  

  attr_readonly   :key
  attr_protected  :editable, :deletable, :deleted  
  
  validates_presence_of :key  
  validate :setting_validations
  if rails3 then validate(:ensure_editable, :on => :update) else validate_on_update(:ensure_editable) end
  
  serialize :value
  
  default_scope :conditions => ['deleted = ? or deleted IS NULL', false]
  
  scope_method = rails3 ? :scope : :named_scope
  send scope_method, :editable, :conditions => { :editable => true }
  send scope_method, :deletable, :conditions => { :deletable => true }  
  
  # Returns the value, typecasted if a typecaster is available.
  def value
    typecast.present? ? typecasted_value : super
  end
  
  # Reads the raw, untypecasted value.
  def untypecasted_value
    read_attribute(:value)
  end

  # Returns the typecasted value or the raw value if a typecaster could not be found.
  def typecasted_value
    typecaster.present? ? typecaster.typecast(untypecasted_value) : untypecasted_value
  end
  
  # Finds the typecast for this key in the settler configuration.
  def typecast
    @typecast ||= Settler.typecast_for(key)
  end
  
  # Returns all valid values for this setting, which is based on the presence of an inclusion validator.
  # Will return nil if no valid values could be determined.
  def valid_values
    if validators['inclusion']
      return case
        when validators['inclusion'].is_a?(Array) then validators['inclusion']
        when validators['inclusion'].is_a?(String) then validators['inclusion'].to_s.split(',').map{|v| v.to_s.strip }
        else nil
      end
    end
    nil
  end
  
  # Performs a soft delete of the setting if this setting is deletable. This ensures this setting is not recreated from the configuraiton file.
  # Returns false if the setting could not be destroyed.
  def destroy    
    if deletable?       
      self.deleted = true if Setting.update_all({ :deleted => true }, { :id => self })
      deleted?
    else 
      false
    end
  end
  
  # Resets this setting to the default stored in the settler configuration
  def reset!
    defaults = Settler.config[self.key]
    self.alt = defaults['alt']
    self.value = defaults['value']
    self.editable = defaults['editable']
    self.deletable = defaults['deletable']    
    rails3 ? save(:validate => false) : save(false)
  end
  
  # Can be used to get *all* settings, including deleted settings.
  def self.without_default_scope &block
    Setting.with_exclusive_scope(&block)
  end
  
  # Deleted scope is specified as a method as it needs to be an exclusive scope
  def self.deleted
    Setting.without_default_scope{ Setting.all :conditions => { :deleted => true } }
  end 
  
private

  # Performs instance validations as defined in the settler configuration.
  def setting_validations
    if errors.empty?
      errors.add(:value, I18n.t(:blank, :scope => 'activerecord.errors.messages')) if validators['presence'] && ['1','true',true].include?(validators['presence']) && self.value.nil?
      errors.add(:value, I18n.t(:inclusion, :scope => 'activerecord.errors.messages')) if valid_values && !valid_values.include?(self.value)
      errors.add(:value, I18n.t(:invalid, :scope => 'activerecord.errors.messages')) if validators['format'] && !(Regexp.new(validators['format']) =~ self.value)
    end
  end
  
  # Retrieves all validators defined for this setting.
  def validators
    @validators ||= Settler.validations_for(self.key)
  end
  
  # Retrieves the typecaster instance that will typecast the value of this setting.
  def typecaster
    @typecaster ||= Typecaster.typecaster_for(typecast)    
  end
  
  # Ensures uneditable settings cannot be updated.
  def ensure_editable
    errors.add(:value, I18n.t('settler.errors.editable', :default => 'cannot be changed')) if value_changed? && !editable? 
  end 
    
end