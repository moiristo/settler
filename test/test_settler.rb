require 'helper'

class TestSettler < Test::Unit::TestCase
  def setup
    Setting.without_default_scope{ Setting.delete_all }
    Settler.source = File.dirname(__FILE__) + '/settler.yml'
    Settler.namespace = 'settings'    
    Settler.load!
  end
    
  def test_should_load_settings
    assert_equal ["bool_value", "custom_value", "float_value", "google_analytics_key", "integer_value", "search_algorithm"], Settler.settings(:order => :key) 
  end
  
  def test_should_find_setting_value
    assert_equal 'ferret', Settler[:search_algorithm]
    assert_equal 'ferret', Settler.search_algorithm.value
  end
  
  def test_should_get_validations_for_setting
    assert Settler.validations_for(:google_analytics_key).keys.include?('presence')
    assert_equal({"inclusion"=>["ferret", "sphinx"]}, Settler.validations_for(:search_algorithm))
  end
  
  def test_should_not_create_instance
    assert_raise NoMethodError do 
      Settler.new
    end
  end
  
  def test_should_report_or_raise_missing    
    #Settler.report_missing = true    
    Settler.raise_missing = true
    
    assert_raise RuntimeError do
      Settler.missing_setting 
    end      
  end
  
  def test_should_not_destroy_undeletable_setting
    assert !Settler.google_analytics_key.destroy
    assert !Settler.google_analytics_key.deleted?
  end
  
  def test_should_destroy_setting
    deletable_setting = Settler.search_algorithm
    assert deletable_setting.deletable?
    assert deletable_setting.destroy
    assert_equal true, deletable_setting.deleted?
    Settler.load!
    assert_nil Settler.search_algorithm
  end
  
  def test_should_delete_destroy_setting
    deletable_setting = Settler.search_algorithm
    assert deletable_setting.destroy
    deletable_setting.delete
    assert Setting.deleted.empty?
    Settler.load!
    assert Settler.search_algorithm.present?
  end  
  
  def test_should_not_update_uneditable_setting
    uneditable_setting = Settler.search_algorithm
    assert !uneditable_setting.update_attributes(:value => 'sphinx')
    assert Setting.rails3 ? uneditable_setting.errors[:value].any? : uneditable_setting.errors.on(:value).present?
    assert_equal 'ferret', Settler[:search_algorithm]
  end
  
  def test_should_manually_update_uneditable_setting
    uneditable_setting = Settler.search_algorithm
    assert uneditable_setting.update_attribute(:value, 'sphinx')
    assert Setting.rails3 ? uneditable_setting.errors[:value].empty? : uneditable_setting.errors.on(:value).nil?
    assert_equal 'sphinx', Settler[:search_algorithm]
  end  
  
  def test_should_update_editable_setting
    editable_setting = Settler.google_analytics_key
    assert editable_setting.update_attributes(:value => 'UA-xxxxxx-1')
    assert_equal 'UA-xxxxxx-1', Settler[:google_analytics_key]
  end
  
  def test_key_should_be_readonly_attribute
    setting = Settler.google_analytics_key
    setting.update_attribute(:key, 'new_key') rescue nil
    assert_equal 'google_analytics_key', setting.reload.key
  end
  
  def test_should_not_update_protected_attributes
    setting = Settler.google_analytics_key
    assert setting.update_attributes(:key => 'new_key', :alt => 'new_alt', :value => 'UA-xxxxxx-1', :editable => false, :deletable => true, :deleted => true)
    setting.reload
    assert_equal 'google_analytics_key', setting.key
    assert_equal 'new_alt', setting.alt         
    assert_equal 'UA-xxxxxx-1', setting.value    
    assert setting.editable?        
    assert !setting.deletable?
    assert_nil setting.deleted    
  end
  
  def test_should_get_scopes
    assert_equal [Settler.google_analytics_key], Setting.editable
    assert_equal [Settler.search_algorithm], Setting.deletable

    assert_equal [], Setting.deleted        
    deletable_setting = Settler.search_algorithm
    assert deletable_setting.destroy
    assert_equal [deletable_setting], Setting.deleted    
  end
  
  def test_should_typecast
    require 'custom_typecaster'
    assert_equal 3, Settler.integer_value.value
    assert_equal 0.25, Settler.float_value.value
    assert_equal true, Settler.bool_value.value        
    assert_equal 'custom value', Settler.custom_value.value                  
  end
  
  def test_boolean_typecaster
    bool_setting = Settler.bool_value
    assert_equal true, bool_setting.value
    bool_setting.update_attribute(:value, false)      
    assert_equal false, bool_setting.value    
    bool_setting.update_attribute(:value, 'f')      
    assert_equal false, bool_setting.value      
    bool_setting.update_attribute(:value, 'bla')      
    assert_equal false, bool_setting.value          
    bool_setting.update_attribute(:value, 't')      
    assert_equal true, bool_setting.value     
    bool_setting.update_attribute(:value, 'true')      
    assert_equal true, bool_setting.value  
    bool_setting.update_attribute(:value, 'TrUe')      
    assert_equal true, bool_setting.value    
    bool_setting.update_attribute(:value, 'tr')      
    assert_equal false, bool_setting.value        
  end
  
  def test_should_validate_format
    setting = Settler.google_analytics_key
    assert !setting.update_attributes(:value => 'invalid_format')    
  end
  
  def test_should_reset_setting
    uneditable_setting = Settler.search_algorithm
    assert uneditable_setting.update_attribute(:deletable, false)
    assert uneditable_setting.update_attribute(:value, 'sphinx')
    assert_equal 'sphinx', Settler[:search_algorithm]
    assert !uneditable_setting.deletable?
    
    uneditable_setting.reset!
    assert_equal 'ferret', Settler[:search_algorithm] 
    assert uneditable_setting.deletable?    
  end  
  
  def test_should_undelete_when_resetting
    deleted_setting = Settler.search_algorithm
    assert deleted_setting.destroy
    assert Setting.deleted.include?(deleted_setting)
    deleted_setting.reset!
    assert !Setting.deleted.include?(deleted_setting)    
  end
  
end
