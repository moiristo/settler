# The Setting class is an AR model that encapsulates a Settler setting. The key if the setting is the only required attribute.\
class Setting < ActiveRecord::Base  
  before_update :ensure_editable
  
  validates_presence_of :key  
  validate :setting_validations
  
  serialize :value
  
  default_scope :conditions => ['deleted = ? or deleted IS NULL', false]
  
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
  
  # Can be used to get *all* settings, including deleted settings.
  def self.without_default_scope &block
    Setting.with_exclusive_scope(&block)
  end
  
protected

  # Performs instance validations as defined in the settler configuration.
  def setting_validations
    errors.add(:value, I18n.t(:blank, :scope => 'activerecord.errors.messages')) if validators['presence'] && ['1','true',true].include?(validators['presence']) && self.value.nil?
    errors.add(:value, I18n.t(:inclusion, :scope => 'activerecord.errors.messages')) if valid_values && !valid_values.include?(self.value)
  end
  
  # Retrieves all validators defined for this setting.
  def validators
    @validators ||= Settler.validations_for(self.key)
  end
  
  # Before_update filter to ensure uneditable settings cannot be updated.
  def ensure_editable;  return false unless editable?  end  
    
end