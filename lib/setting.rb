require 'type_casters'

# The Setting class is an AR model that encapsulates a Settler setting. The key if the setting is the only required attribute.\
class Setting < ActiveRecord::Base  

  attr_readonly   :key
  attr_accessible :key, :label, :value if ActiveRecord::VERSION::MAJOR < 4

  serialize :value
  
  validates :key, :presence => true
  validate  :setting_validations
  validate  :ensure_editable, :on => :update  

  default_scope { where(['deleted = ? or deleted IS NULL', false]) }
  
  scope :editable, lambda{ where(:editable => true) }
  scope :deletable, lambda{ where(:deletable => true) }
  
  # Returns the value, typecasted if a typecaster is available.
  def value
    typecast.present? ? typecasted_value : super
  end
  
  def value=(val)
    typecaster.present? && typecaster.typecast_on_write? ? write_attribute(:value, typecaster.typecast_on_write(val)) : super
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
  
  def type
    @type ||= ActiveSupport::StringInquirer.new(typecaster.try(:type) || 'string')
  end
  
  def to_label
    label.present? ? label : key
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
      self.deleted = true if Setting.where(:id => self).update_all(:deleted => true)
      deleted?
    else 
      false
    end
  end
  
  # Overrides the delete methods to ensure the default scope is not passed in the query
  def delete *args;           Setting.unscoped{ super } end  
  def self.delete_all *args;  Setting.unscoped{ super } end    
  
  # Resets this setting to the default stored in the settler configuration
  def reset!
    defaults = Settler.config[self.key]
    self.label = defaults['label']
    self.value = defaults['value']
    self.editable = defaults['editable']
    self.deletable = defaults['deletable']    
    self.deleted = false    
    save(:validate => false)
  end
  
  # Deleted scope is specified as a method as it needs to be an exclusive scope
  def self.deleted
    unscoped { Setting.where(:deleted => true) }
  end 
  
private

  # Performs instance validations as defined in the settler configuration.
  def setting_validations
    if errors.empty?
      errors.add(:value, :blank) if validators['presence'] && ['1','true',true].include?(validators['presence']) && self.value.nil?
      errors.add(:value, :inclusion) if valid_values && !valid_values.include?(self.value)
      errors.add(:value, :invalid) if validators['format'] && !(Regexp.new(validators['format']) =~ self.value)
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
    errors.add(:base, I18n.t('settler.errors.editable', :default => 'Setting cannot be changed')) if changed? && !editable? 
  end 
    
end